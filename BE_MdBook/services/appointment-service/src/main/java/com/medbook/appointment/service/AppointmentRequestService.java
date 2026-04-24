package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.AppointmentRequestConfirmRequest;
import com.medbook.appointment.dto.request.AppointmentRequestCreateRequest;
import com.medbook.appointment.dto.request.AppointmentRequestRejectRequest;
import com.medbook.appointment.dto.response.AppointmentRequestResponse;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.entity.AppointmentRequest;
import com.medbook.appointment.exception.AppointmentRequestNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.repository.AppointmentRequestRepository;
import com.medbook.appointment.service.command.CreateAppointmentCommand;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional
public class AppointmentRequestService {

    AppointmentRequestRepository appointmentRequestRepository;
    AppointmentService appointmentService;

    public AppointmentRequestResponse createRequest(AppointmentRequestCreateRequest request, String patientUserId) {
        AppointmentRequest appointmentRequest = AppointmentRequest.builder()
                .patientUserId(patientUserId)
                .doctorId(request.getDoctorId())
                .doctorScheduleId(request.getDoctorScheduleId())
                .roomSlotId(request.getRoomSlotId())
                .packageId(request.getPackageId())
                .status(AppointmentRequest.RequestStatus.PENDING_ASSIGNMENT)
                .note(request.getNote())
                .build();

        AppointmentRequest savedRequest = appointmentRequestRepository.save(appointmentRequest);
        appointmentService.sendPendingRequestNotificationAsync(patientUserId, request.getDoctorId(), request.getPackageId());

        return toResponse(savedRequest);
    }

    @Transactional(readOnly = true)
    public AppointmentRequestResponse getRequest(String requestId) {
        return toResponse(getRequestEntity(requestId));
    }

    @Transactional(readOnly = true)
    public Page<AppointmentRequestResponse> getMyRequests(String patientUserId, Pageable pageable) {
        return appointmentRequestRepository.findByPatientUserIdOrderByCreatedAtDesc(patientUserId, pageable)
                .map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<AppointmentRequestResponse> getPendingRequests(Pageable pageable) {
        return appointmentRequestRepository.findByStatusOrderByCreatedAtAsc(
                        AppointmentRequest.RequestStatus.PENDING_ASSIGNMENT, pageable)
                .map(this::toResponse);
    }

    public AppointmentResponse confirmRequest(
            String requestId,
            AppointmentRequestConfirmRequest request,
            String actorUserId) {
        AppointmentRequest appointmentRequest = getRequestEntity(requestId);
        ensurePendingAssignment(appointmentRequest);

        AppointmentResponse appointmentResponse = appointmentService.createConfirmedAppointment(
                CreateAppointmentCommand.builder()
                        .packageId(appointmentRequest.getPackageId())
                        .doctorId(appointmentRequest.getDoctorId())
                        .doctorScheduleId(appointmentRequest.getDoctorScheduleId())
                        .roomSlotId(request.getRoomSlotId() != null ? request.getRoomSlotId() : appointmentRequest.getRoomSlotId())
                        .facilityId(request.getFacilityId())
                        .note(appointmentRequest.getNote())
                        .build(),
                appointmentRequest.getPatientUserId());

        appointmentRequest.setStatus(AppointmentRequest.RequestStatus.CONFIRMED);
        appointmentRequest.setFacilityId(request.getFacilityId());
        appointmentRequest.setRoomSlotId(request.getRoomSlotId());
        appointmentRequest.setAppointmentId(appointmentResponse.getId());
        appointmentRequest.setProcessedBy(actorUserId);
        appointmentRequest.setProcessedAt(LocalDateTime.now());
        appointmentRequest.setRejectionReason(null);
        appointmentRequestRepository.save(appointmentRequest);

        return appointmentResponse;
    }

    public AppointmentRequestResponse rejectRequest(
            String requestId,
            AppointmentRequestRejectRequest request,
            String actorUserId) {
        AppointmentRequest appointmentRequest = getRequestEntity(requestId);
        ensurePendingAssignment(appointmentRequest);

        appointmentRequest.setStatus(AppointmentRequest.RequestStatus.REJECTED);
        appointmentRequest.setProcessedBy(actorUserId);
        appointmentRequest.setProcessedAt(LocalDateTime.now());
        appointmentRequest.setRejectionReason(request.getReason());

        String message = "Rất tiếc! Yêu cầu đặt lịch của bạn đã bị bác sĩ từ chối.";
        if (request.getReason() != null && !request.getReason().isBlank()) {
            message += " Lý do: " + request.getReason();
        }
        appointmentService.sendGenericNotificationAsync(appointmentRequest.getPatientUserId(), "Từ chối lịch hẹn", message);

        return toResponse(appointmentRequestRepository.save(appointmentRequest));
    }

    public AppointmentRequestResponse cancelRequest(String requestId, String patientUserId) {
        AppointmentRequest appointmentRequest = getRequestEntity(requestId);
        
        if (!appointmentRequest.getPatientUserId().equals(patientUserId)) {
            throw new AppointmentValidationException("Unauthorized to cancel this request");
        }
        
        if (appointmentRequest.getStatus() != AppointmentRequest.RequestStatus.PENDING_ASSIGNMENT) {
            throw new AppointmentValidationException("Only pending requests can be cancelled");
        }

        appointmentRequest.setStatus(AppointmentRequest.RequestStatus.CANCELLED);
        appointmentRequest.setProcessedAt(LocalDateTime.now());

        appointmentService.sendGenericNotificationAsync(appointmentRequest.getPatientUserId(), "Hủy yêu cầu thành công", "Bạn đã hủy yêu cầu đặt lịch trước đó.");

        return toResponse(appointmentRequestRepository.save(appointmentRequest));
    }

    private AppointmentRequest getRequestEntity(String requestId) {
        return appointmentRequestRepository.findById(requestId)
                .orElseThrow(() -> new AppointmentRequestNotFoundException(
                        "Appointment request not found: " + requestId));
    }

    private void ensurePendingAssignment(AppointmentRequest appointmentRequest) {
        if (appointmentRequest.getStatus() != AppointmentRequest.RequestStatus.PENDING_ASSIGNMENT) {
            throw new AppointmentValidationException("Appointment request is not pending assignment");
        }
    }

    private AppointmentRequestResponse toResponse(AppointmentRequest appointmentRequest) {
        return AppointmentRequestResponse.builder()
                .id(appointmentRequest.getId())
                .patientUserId(appointmentRequest.getPatientUserId())
                .doctorId(appointmentRequest.getDoctorId())
                .doctorScheduleId(appointmentRequest.getDoctorScheduleId())
                .packageId(appointmentRequest.getPackageId())
                .facilityId(appointmentRequest.getFacilityId())
                .roomSlotId(appointmentRequest.getRoomSlotId())
                .status(appointmentRequest.getStatus().name())
                .note(appointmentRequest.getNote())
                .appointmentId(appointmentRequest.getAppointmentId())
                .processedBy(appointmentRequest.getProcessedBy())
                .processedAt(appointmentRequest.getProcessedAt())
                .rejectionReason(appointmentRequest.getRejectionReason())
                .createdAt(appointmentRequest.getCreatedAt())
                .updatedAt(appointmentRequest.getUpdatedAt())
                .build();
    }
}
