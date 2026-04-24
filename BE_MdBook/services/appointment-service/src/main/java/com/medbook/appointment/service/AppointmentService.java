package com.medbook.appointment.service;

import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.client.profile.ProfileServiceClient;
import com.medbook.appointment.client.profile.InternalUserProfileResponse;
import com.medbook.appointment.dto.ApiResponse;
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
import com.medbook.appointment.repository.AppointmentRequestRepository;
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
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional
@Slf4j
public class AppointmentService {

    AppointmentRepository appointmentRepository;
    AppointmentRequestRepository appointmentRequestRepository;
    AppointmentMapper appointmentMapper;
    ExamPackageService examPackageService;
    DoctorServiceClient doctorServiceClient;
    SlotServiceClient slotServiceClient;
    ProfileServiceClient profileServiceClient;
    NotificationService notificationService;

    AppointmentResponse createConfirmedAppointment(CreateAppointmentCommand request, String patientUserId) {
        log.info("Creating appointment for user: {}", patientUserId);

        validateCreateRequest(request);

        DoctorScheduleInfo schedule = doctorServiceClient.getDoctorScheduleById(
                String.valueOf(request.getDoctorScheduleId()), request.getDoctorId());

        LocalDate appointmentDate = LocalDate.parse(schedule.date());
        LocalTime startTime = LocalTime.parse(schedule.startTime());

        Appointment appointment = Appointment.builder()
                .id(UUID.randomUUID().toString())
                .patientUserId(patientUserId)
                .doctorId(request.getDoctorId())
                .doctorScheduleId(request.getDoctorScheduleId())
                .roomSlotId(request.getRoomSlotId())
                .appointmentDate(appointmentDate)
                .startTime(startTime)
                .facilityId(request.getFacilityId() != null ? request.getFacilityId() : "default")
                .packageId(request.getPackageId())
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .note(request.getNote())
                .build();

        boolean doctorReserved = false;
        boolean roomReserved = false;

        try {
            doctorServiceClient.reserveSchedule(request.getDoctorScheduleId(), appointment.getId());
            doctorReserved = true;

            slotServiceClient.reserveSlot(request.getRoomSlotId(), appointment.getId());
            roomReserved = true;


            Appointment saved = appointmentRepository.save(appointment);
            log.info("Appointment confirmed: {}", saved.getId());

            sendBookingNotificationAsync(request, patientUserId, saved);

            return appointmentMapper.toResponse(saved);

        } catch (RuntimeException ex) {
            log.error("Booking failed, rolling back: {}", ex.getMessage());
            rollback(appointment.getId(), request, doctorReserved, roomReserved);
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
        
        // Sync status with AppointmentRequest
        appointmentRequestRepository.findByAppointmentId(appointmentId).ifPresent(req -> {
            req.setStatus(com.medbook.appointment.entity.AppointmentRequest.RequestStatus.CANCELLED);
            appointmentRequestRepository.save(req);
        });

        return appointmentMapper.toResponse(appointmentRepository.save(appointment));
    }

    public AppointmentResponse completeAppointment(String appointmentId) {
        Appointment appointment = findById(appointmentId);

        if (appointment.getStatus() != Appointment.AppointmentStatus.CONFIRMED) {
            throw new AppointmentValidationException("Only confirmed appointments can be completed");
        }

        releaseReservedResources(appointment);

        appointment.setStatus(Appointment.AppointmentStatus.COMPLETED);

        // Sync status with AppointmentRequest
        appointmentRequestRepository.findByAppointmentId(appointmentId).ifPresent(req -> {
            req.setStatus(com.medbook.appointment.entity.AppointmentRequest.RequestStatus.COMPLETED);
            appointmentRequestRepository.save(req);
        });

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
        // Cho phép cả ACTIVE và PENDING trong môi trường dev/test hoặc nếu doctor mới tạo
        if (!doctor.active() && !"PENDING".equalsIgnoreCase(doctor.status())) {
            throw new AppointmentValidationException("Doctor is inactive (Status: " + doctor.status() + ")");
        }

        // We already checked doctorScheduleInfo for date extraction, no need to check here again. 
        // Although the old code checked availability. We should keep it for validation if we don't query it before. 
        // Wait, validateCreateRequest is called before we query schedule in createConfirmedAppointment. 
        // I will let validateCreateRequest query it normally, since Feign client responses are cached or fast anyway.
        DoctorScheduleInfo schedule = doctorServiceClient.getDoctorScheduleById(
                String.valueOf(request.getDoctorScheduleId()), request.getDoctorId());
        if (!schedule.available()) {
            throw new DoctorScheduleNotFoundException("Doctor schedule is not available");
        }
    }

    private void rollback(String appointmentId, CreateAppointmentCommand request,
                          boolean doctorReserved, boolean roomReserved) {
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
    }

    private void safeRelease(Runnable action) {
        try {
            action.run();
        } catch (Exception e) {
            log.warn("Rollback failed: {}", e.getMessage());
        }
    }

    private void sendBookingNotificationAsync(CreateAppointmentCommand request, String patientUserId, Appointment appointment) {
        CompletableFuture.runAsync(() -> {
            try {
                var examPackage = examPackageService.getPackageById(request.getPackageId());
                var doctorInfo = doctorServiceClient.getDoctorById(request.getDoctorId());
                
                ApiResponse<InternalUserProfileResponse> response = profileServiceClient.getInternalProfile(patientUserId);
                if (response.getResult() != null && response.getResult().getFcmToken() != null && !response.getResult().getFcmToken().isBlank()) {
                    String title = "Đặt lịch thành công!";
                    String message = String.format(
                            "Bạn có lịch hẹn với BS. %s\n" +
                            "Gói khám: %s\n" +
                            "Thời gian: %s - %s",
                            doctorInfo.firstName() + " " + doctorInfo.lastName(),
                            examPackage.getName(),
                            appointment.getStartTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                            appointment.getAppointmentDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                    );
                    notificationService.sendPushNotification(response.getResult().getFcmToken(), title, message);
                }
            } catch (Exception e) {
                log.error("Failed to send booking notification async", e);
            }
        });
    }
}
