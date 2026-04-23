package com.medbook.appointment.service;

import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.client.slot.SlotServiceClient;
import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.mapper.AppointmentMapper;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.service.command.CreateAppointmentCommand;
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
    DoctorServiceClient doctorServiceClient;
    SlotServiceClient slotServiceClient;

    AppointmentResponse createConfirmedAppointment(CreateAppointmentCommand request, String patientUserId) {
        log.info("Creating appointment for user: {}", patientUserId);

        validateCreateRequest(request);

        Appointment appointment = Appointment.builder()
                .id(UUID.randomUUID().toString())
                .patientUserId(patientUserId)
                .doctorId(request.getDoctorId())
                .doctorScheduleId(request.getDoctorScheduleId())
                .roomSlotId(request.getRoomSlotId())
                .equipmentSlotId(request.getEquipmentSlotId())
                .facilityId(request.getFacilityId() != null ? request.getFacilityId() : "default")
                .packageId(request.getPackageId())
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .note(request.getNote())
                .build();

        boolean doctorReserved = false;
        boolean roomReserved = false;
        boolean equipmentReserved = false;

        try {
            doctorServiceClient.reserveSchedule(request.getDoctorScheduleId(), appointment.getId());
            doctorReserved = true;

            slotServiceClient.reserveSlot(request.getRoomSlotId(), appointment.getId());
            roomReserved = true;

            if (request.getEquipmentSlotId() != null) {
                slotServiceClient.reserveSlot(request.getEquipmentSlotId(), appointment.getId());
                equipmentReserved = true;
            }

            Appointment saved = appointmentRepository.save(appointment);
            log.info("Appointment confirmed: {}", saved.getId());

            return appointmentMapper.toResponse(saved);

        } catch (RuntimeException ex) {
            log.error("Booking failed, rolling back: {}", ex.getMessage());
            rollback(appointment.getId(), request, doctorReserved, roomReserved, equipmentReserved);
            throw ex;
        }
    }

    public AppointmentResponse cancelAppointment(String appointmentId, CancelAppointmentRequest request, String patientUserId) {
        Appointment appointment = findById(appointmentId);

        if (!appointment.getPatientUserId().equals(patientUserId)) {
            throw new AppointmentAccessDeniedException("Unauthorized to cancel this appointment");
        }
        if (appointment.getStatus() != Appointment.AppointmentStatus.CONFIRMED) {
            throw new AppointmentValidationException("Only confirmed appointments can be cancelled");
        }

        releaseReservedResources(appointment);

        appointment.setStatus(Appointment.AppointmentStatus.CANCELLED);
        appointment.setCancelReason(request.getReason());
        return appointmentMapper.toResponse(appointmentRepository.save(appointment));
    }

    public AppointmentResponse completeAppointment(String appointmentId) {
        Appointment appointment = findById(appointmentId);

        if (appointment.getStatus() != Appointment.AppointmentStatus.CONFIRMED) {
            throw new AppointmentValidationException("Only confirmed appointments can be completed");
        }

        releaseReservedResources(appointment);

        appointment.setStatus(Appointment.AppointmentStatus.COMPLETED);
        return appointmentMapper.toResponse(appointmentRepository.save(appointment));
    }

    @Transactional(readOnly = true)
    public AppointmentResponse getAppointment(String appointmentId) {
        return appointmentMapper.toResponse(findById(appointmentId));
    }

    @Transactional(readOnly = true)
    public AppointmentStatusResponse getAppointmentStatus(String appointmentId) {
        return appointmentMapper.toStatusResponse(findById(appointmentId));
    }

    @Transactional(readOnly = true)
    public Page<AppointmentResponse> getMyAppointments(String patientUserId, Pageable pageable) {
        return appointmentRepository.findByPatientUserId(patientUserId, pageable).map(appointmentMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<AppointmentResponse> getDoctorAppointments(String doctorId, Pageable pageable) {
        return appointmentRepository.findByDoctorId(doctorId, pageable).map(appointmentMapper::toResponse);
    }

    private Appointment findById(String id) {
        return appointmentRepository.findById(id)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + id));
    }

    private void validateCreateRequest(CreateAppointmentCommand request) {
        if (request.getDoctorId() == null || request.getDoctorId().isBlank()) {
            throw new AppointmentValidationException("Doctor ID is required");
        }
        if (request.getDoctorScheduleId() == null) {
            throw new AppointmentValidationException("Doctor schedule ID is required");
        }
        if (request.getRoomSlotId() == null) {
            throw new AppointmentValidationException("Room slot ID is required");
        }
        if (request.getFacilityId() == null || request.getFacilityId().isBlank()) {
            throw new AppointmentValidationException("Facility ID is required");
        }

        try {
            examPackageService.getPackageById(request.getPackageId());
        } catch (Exception e) {
            throw new AppointmentValidationException("Package not found: " + request.getPackageId());
        }

        DoctorInfo doctor = doctorServiceClient.getDoctorById(request.getDoctorId());
        if (!doctor.active()) {
            throw new AppointmentValidationException("Doctor is inactive");
        }

        DoctorScheduleInfo schedule = doctorServiceClient.getDoctorScheduleById(
                String.valueOf(request.getDoctorScheduleId()), request.getDoctorId());
        if (!schedule.available()) {
            throw new DoctorScheduleNotFoundException("Doctor schedule is not available");
        }
    }

    private void rollback(String appointmentId, CreateAppointmentCommand request,
                          boolean doctorReserved, boolean roomReserved, boolean equipmentReserved) {
        if (equipmentReserved && request.getEquipmentSlotId() != null) {
            safeRelease(() -> slotServiceClient.releaseSlot(request.getEquipmentSlotId(), appointmentId));
        }
        if (roomReserved) {
            safeRelease(() -> slotServiceClient.releaseSlot(request.getRoomSlotId(), appointmentId));
        }
        if (doctorReserved) {
            safeRelease(() -> doctorServiceClient.releaseSchedule(request.getDoctorScheduleId(), appointmentId));
        }
    }

    private void releaseReservedResources(Appointment appointment) {
        safeRelease(() -> doctorServiceClient.releaseSchedule(appointment.getDoctorScheduleId(), appointment.getId()));
        if (appointment.getRoomSlotId() != null) {
            safeRelease(() -> slotServiceClient.releaseSlot(appointment.getRoomSlotId(), appointment.getId()));
        }
        if (appointment.getEquipmentSlotId() != null) {
            safeRelease(() -> slotServiceClient.releaseSlot(appointment.getEquipmentSlotId(), appointment.getId()));
        }
    }

    private void safeRelease(Runnable action) {
        try {
            action.run();
        } catch (Exception e) {
            log.warn("Rollback failed: {}", e.getMessage());
        }
    }
}
