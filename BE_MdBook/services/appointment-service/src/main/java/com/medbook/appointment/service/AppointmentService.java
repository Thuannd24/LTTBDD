package com.medbook.appointment.service;

import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.client.model.EquipmentInfo;
import com.medbook.appointment.client.model.RoomInfo;
import com.medbook.appointment.client.model.SlotInfo;
import com.medbook.appointment.client.slot.SlotServiceClient;
import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.request.CreateAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.dto.response.CreateAppointmentResponse;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.entity.AppointmentResourceReservation;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.exception.SlotNotFoundException;
import com.medbook.appointment.mapper.AppointmentMapper;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.repository.AppointmentResourceReservationRepository;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional
@Slf4j
public class AppointmentService {

    AppointmentRepository appointmentRepository;
    AppointmentMapper appointmentMapper;
    ExamPackageService examPackageService;
    ExamPackageStepService examPackageStepService;
    DoctorServiceClient doctorServiceClient;
    SlotServiceClient slotServiceClient;
    AppointmentResourceReservationRepository appointmentResourceReservationRepository;

    public CreateAppointmentResponse createAppointment(
            CreateAppointmentRequest request,
            String patientUserId) {

        log.info("Creating appointment for user: {} with package: {}", patientUserId, request.getPackageId());

        validateCreateAppointmentRequest(request);

        Appointment appointment = Appointment.builder()
                .id(UUID.randomUUID().toString())
                .patientUserId(patientUserId)
                .doctorId(request.getDoctorId())
                .doctorScheduleId(request.getDoctorScheduleId())
                .facilityId(request.getFacilityId() != null ? request.getFacilityId() : "default")
                .packageId(request.getPackageId())
                .packageStepId(request.getPackageStepId())
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .note(request.getNote())
                .build();

        Appointment saved = appointment;

        boolean doctorReserved = false;
        boolean roomReserved = false;
        boolean equipmentReserved = false;

        try {
            doctorServiceClient.reserveSchedule(saved.getDoctorScheduleId(), saved.getId());
            doctorReserved = true;
            upsertReservation(
                    saved.getId(),
                    AppointmentResourceReservation.ResourceTargetType.DOCTOR,
                    String.valueOf(saved.getDoctorScheduleId()),
                    saved.getDoctorId(),
                    AppointmentResourceReservation.ReservationStatus.RESERVED);

            slotServiceClient.reserveSlot(request.getRoomSlotId(), saved.getId());
            roomReserved = true;
            upsertReservation(
                    saved.getId(),
                    AppointmentResourceReservation.ResourceTargetType.ROOM,
                    String.valueOf(request.getRoomSlotId()),
                    String.valueOf(request.getRoomSlotId()),
                    AppointmentResourceReservation.ReservationStatus.RESERVED);

            if (request.getEquipmentSlotId() != null) {
                slotServiceClient.reserveSlot(request.getEquipmentSlotId(), saved.getId());
                equipmentReserved = true;
                upsertReservation(
                        saved.getId(),
                        AppointmentResourceReservation.ResourceTargetType.EQUIPMENT,
                        String.valueOf(request.getEquipmentSlotId()),
                        String.valueOf(request.getEquipmentSlotId()),
                        AppointmentResourceReservation.ReservationStatus.RESERVED);
            }

            saved.setFailureCode(null);
            saved.setFailureMessage(null);
            saved = appointmentRepository.save(saved);
            log.info("Appointment created and confirmed immediately: {}", saved.getId());

            return CreateAppointmentResponse.builder()
                    .appointmentId(saved.getId())
                    .status(saved.getStatus().name())
                    .build();
        } catch (RuntimeException ex) {
            rollbackBooking(saved, request, doctorReserved, roomReserved, equipmentReserved);
            saved.setStatus(Appointment.AppointmentStatus.BOOKING_FAILED);
            saved.setFailureCode(ex.getClass().getSimpleName());
            saved.setFailureMessage(ex.getMessage());
            appointmentRepository.save(saved);
            throw ex;
        }
    }

    @Transactional(readOnly = true)
    public AppointmentResponse getAppointment(String appointmentId) {
        log.debug("Fetching appointment: {}", appointmentId);

        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));

        return appointmentMapper.toResponse(appointment);
    }

    @Transactional(readOnly = true)
    public AppointmentStatusResponse getAppointmentStatus(String appointmentId) {
        log.debug("Fetching appointment status: {}", appointmentId);

        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));

        return appointmentMapper.toStatusResponse(appointment);
    }

    @Transactional(readOnly = true)
    public Page<AppointmentResponse> getMyAppointments(String patientUserId, Pageable pageable) {
        log.debug("Fetching appointments for patient: {}", patientUserId);

        return appointmentRepository
                .findByPatientUserId(patientUserId, pageable)
                .map(appointmentMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<AppointmentResponse> getDoctorAppointments(String doctorId, Pageable pageable) {
        log.debug("Fetching appointments for doctor: {}", doctorId);

        return appointmentRepository
                .findByDoctorId(doctorId, pageable)
                .map(appointmentMapper::toResponse);
    }

    public AppointmentResponse cancelAppointment(
            String appointmentId,
            CancelAppointmentRequest request,
            String patientUserId) {

        log.info("Cancelling appointment: {} for user: {}", appointmentId, patientUserId);

        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));

        if (!appointment.getPatientUserId().equals(patientUserId)) {
            throw new AppointmentAccessDeniedException("Unauthorized to cancel this appointment");
        }

        if (appointment.getStatus() != Appointment.AppointmentStatus.CONFIRMED) {
            throw new AppointmentValidationException("Only confirmed appointments can be cancelled");
        }

        List<AppointmentResourceReservation> reservations = appointmentResourceReservationRepository
                .findByAppointmentId(appointmentId)
                .stream()
                .filter(reservation -> reservation.getStatus() == AppointmentResourceReservation.ReservationStatus.RESERVED)
                .sorted(Comparator.comparingInt(this::releasePriority))
                .toList();

        try {
            for (AppointmentResourceReservation reservation : reservations) {
                releaseReservation(appointment, reservation);
                reservation.setStatus(AppointmentResourceReservation.ReservationStatus.RELEASED);
                appointmentResourceReservationRepository.save(reservation);
            }

            appointment.setStatus(Appointment.AppointmentStatus.CANCELLED);
            appointment.setCancelReason(request.getReason());
            appointment.setFailureCode(null);
            appointment.setFailureMessage(null);
            Appointment updatedAppointment = appointmentRepository.save(appointment);
            log.info("Appointment cancelled immediately: {}", appointmentId);
            return appointmentMapper.toResponse(updatedAppointment);
        } catch (RuntimeException ex) {
            appointment.setStatus(Appointment.AppointmentStatus.CANCELLATION_FAILED);
            appointment.setFailureCode(ex.getClass().getSimpleName());
            appointment.setFailureMessage(ex.getMessage());
            appointmentRepository.save(appointment);
            throw ex;
        }
    }

    private void validateCreateAppointmentRequest(CreateAppointmentRequest request) {
        if (request.getDoctorId() == null || request.getDoctorId().isBlank()) {
            throw new AppointmentValidationException("Doctor ID is required");
        }

        if (request.getDoctorScheduleId() == null) {
            throw new AppointmentValidationException("Doctor schedule ID is required");
        }

        if (request.getRoomSlotId() == null) {
            throw new AppointmentValidationException("Room slot ID is required");
        }

        try {
            examPackageService.getPackageById(request.getPackageId());
        } catch (Exception e) {
            throw new AppointmentValidationException("Package not found: " + request.getPackageId());
        }

        ExamPackageStepResponse stepResponse = null;
        if (request.getPackageStepId() != null && !request.getPackageStepId().isBlank()) {
            try {
                stepResponse = examPackageStepService.getStepById(request.getPackageStepId());
            } catch (Exception e) {
                throw new AppointmentValidationException("Package step not found: " + request.getPackageStepId());
            }

            if (!Objects.equals(stepResponse.getPackageId(), request.getPackageId())) {
                throw new AppointmentValidationException("Package step does not belong to the selected package");
            }
        }

        DoctorInfo doctorInfo = doctorServiceClient.getDoctorById(request.getDoctorId());
        if (!doctorInfo.active()) {
            throw new AppointmentValidationException("Doctor is inactive: " + request.getDoctorId());
        }

        DoctorScheduleInfo scheduleInfo = doctorServiceClient.getDoctorScheduleById(
                String.valueOf(request.getDoctorScheduleId()),
                request.getDoctorId());
        if (!Objects.equals(scheduleInfo.doctorId(), request.getDoctorId())) {
            throw new AppointmentValidationException("Doctor schedule does not belong to the selected doctor");
        }
        if (!scheduleInfo.available()) {
            throw new DoctorScheduleNotFoundException("Doctor schedule is not available: " + request.getDoctorScheduleId());
        }

        if (stepResponse != null) {
            validateSpecialty(stepResponse, doctorInfo);
            validateRoomAndEquipment(stepResponse, request);
        }
    }

    private void validateSpecialty(ExamPackageStepResponse stepResponse, DoctorInfo doctorInfo) {
        if (stepResponse.getAllowedSpecialtyIds() == null || stepResponse.getAllowedSpecialtyIds().isEmpty()) {
            return;
        }

        if (doctorInfo.specialtyId() == null || doctorInfo.specialtyId().isBlank()) {
            throw new AppointmentValidationException("Doctor specialty is missing");
        }

        if (!stepResponse.getAllowedSpecialtyIds().contains(doctorInfo.specialtyId())) {
            throw new AppointmentValidationException("Doctor specialty is not allowed for this package step");
        }
    }

    private void validateRoomAndEquipment(ExamPackageStepResponse stepResponse, CreateAppointmentRequest request) {
        SlotInfo roomSlot = slotServiceClient.getSlotById(String.valueOf(request.getRoomSlotId()));
        if (!"ROOM".equalsIgnoreCase(roomSlot.targetType())) {
            throw new SlotNotFoundException("Room slot target type must be ROOM");
        }
        if (!roomSlot.available()) {
            throw new AppointmentValidationException("Room slot is not available: " + request.getRoomSlotId());
        }

        RoomInfo roomInfo = slotServiceClient.getRoomById(roomSlot.targetId());
        if (!roomInfo.active()) {
            throw new AppointmentValidationException("Room is inactive: " + roomInfo.id());
        }

        if (stepResponse.getRequiredRoomCategory() != null
                && !stepResponse.getRequiredRoomCategory().isBlank()
                && !stepResponse.getRequiredRoomCategory().equalsIgnoreCase(roomInfo.category())) {
            throw new AppointmentValidationException("Room category does not match package step requirement");
        }

        if (!Boolean.TRUE.equals(stepResponse.getEquipmentRequired())) {
            if (request.getEquipmentSlotId() != null) {
                throw new AppointmentValidationException("Equipment slot must not be provided for this package step");
            }
            return;
        }

        if (request.getEquipmentSlotId() == null) {
            throw new AppointmentValidationException("Equipment slot ID is required for this package step");
        }

        SlotInfo equipmentSlot = slotServiceClient.getSlotById(String.valueOf(request.getEquipmentSlotId()));
        if (!"EQUIPMENT".equalsIgnoreCase(equipmentSlot.targetType())) {
            throw new SlotNotFoundException("Equipment slot target type must be EQUIPMENT");
        }
        if (!equipmentSlot.available()) {
            throw new AppointmentValidationException("Equipment slot is not available: " + request.getEquipmentSlotId());
        }

        EquipmentInfo equipmentInfo = slotServiceClient.getEquipmentById(equipmentSlot.targetId());
        if (!equipmentInfo.active()) {
            throw new AppointmentValidationException("Equipment is inactive: " + equipmentInfo.id());
        }

        if (stepResponse.getRequiredEquipmentType() != null
                && !stepResponse.getRequiredEquipmentType().isBlank()
                && !stepResponse.getRequiredEquipmentType().equalsIgnoreCase(equipmentInfo.type())) {
            throw new AppointmentValidationException("Equipment type does not match package step requirement");
        }
    }

    private void rollbackBooking(
            Appointment appointment,
            CreateAppointmentRequest request,
            boolean doctorReserved,
            boolean roomReserved,
            boolean equipmentReserved) {
        if (equipmentReserved && request.getEquipmentSlotId() != null) {
            safeReleaseSlot(request.getEquipmentSlotId(), appointment.getId());
            markReservationReleased(
                    appointment.getId(),
                    AppointmentResourceReservation.ResourceTargetType.EQUIPMENT,
                    String.valueOf(request.getEquipmentSlotId()));
        }

        if (roomReserved) {
            safeReleaseSlot(request.getRoomSlotId(), appointment.getId());
            markReservationReleased(
                    appointment.getId(),
                    AppointmentResourceReservation.ResourceTargetType.ROOM,
                    String.valueOf(request.getRoomSlotId()));
        }

        if (doctorReserved) {
            safeReleaseDoctorSchedule(appointment.getDoctorScheduleId(), appointment.getId());
            markReservationReleased(
                    appointment.getId(),
                    AppointmentResourceReservation.ResourceTargetType.DOCTOR,
                    String.valueOf(appointment.getDoctorScheduleId()));
        }
    }

    private void safeReleaseSlot(Long slotId, String appointmentId) {
        try {
            slotServiceClient.releaseSlot(slotId, appointmentId);
        } catch (RuntimeException ex) {
            log.warn("Failed to rollback slot {} for appointment {}: {}", slotId, appointmentId, ex.getMessage());
        }
    }

    private void safeReleaseDoctorSchedule(Long scheduleId, String appointmentId) {
        try {
            doctorServiceClient.releaseSchedule(scheduleId, appointmentId);
        } catch (RuntimeException ex) {
            log.warn("Failed to rollback doctor schedule {} for appointment {}: {}", scheduleId, appointmentId, ex.getMessage());
        }
    }

    private void releaseReservation(Appointment appointment, AppointmentResourceReservation reservation) {
        switch (reservation.getTargetType()) {
            case EQUIPMENT, ROOM -> slotServiceClient.releaseSlot(Long.valueOf(reservation.getSlotId()), appointment.getId());
            case DOCTOR -> doctorServiceClient.releaseSchedule(Long.valueOf(reservation.getSlotId()), appointment.getId());
        }
    }

    private int releasePriority(AppointmentResourceReservation reservation) {
        return switch (reservation.getTargetType()) {
            case EQUIPMENT -> 0;
            case ROOM -> 1;
            case DOCTOR -> 2;
        };
    }

    private void upsertReservation(
            String appointmentId,
            AppointmentResourceReservation.ResourceTargetType targetType,
            String slotId,
            String targetId,
            AppointmentResourceReservation.ReservationStatus status) {
        AppointmentResourceReservation reservation = appointmentResourceReservationRepository
                .findByAppointmentIdAndTargetTypeAndSlotId(appointmentId, targetType, slotId)
                .orElse(AppointmentResourceReservation.builder()
                        .appointmentId(appointmentId)
                        .targetType(targetType)
                        .slotId(slotId)
                        .targetId(targetId)
                        .build());
        reservation.setTargetId(targetId);
        reservation.setStatus(status);
        appointmentResourceReservationRepository.save(reservation);
    }

    private void markReservationReleased(
            String appointmentId,
            AppointmentResourceReservation.ResourceTargetType targetType,
            String slotId) {
        appointmentResourceReservationRepository
                .findByAppointmentIdAndTargetTypeAndSlotId(appointmentId, targetType, slotId)
                .ifPresent(reservation -> {
                    reservation.setStatus(AppointmentResourceReservation.ReservationStatus.RELEASED);
                    appointmentResourceReservationRepository.save(reservation);
                });
    }
}
