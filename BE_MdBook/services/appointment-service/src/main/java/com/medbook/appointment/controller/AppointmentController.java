package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.request.CreateAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.dto.response.CreateAppointmentResponse;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.service.AppointmentService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/appointments")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class AppointmentController {

    AppointmentService appointmentService;

    @PostMapping
    public ResponseEntity<ApiResponse<CreateAppointmentResponse>> createAppointment(
            @RequestBody @Valid CreateAppointmentRequest request) {

        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("POST /appointments - Creating appointment for user: {}", userId);

        CreateAppointmentResponse response = appointmentService.createAppointment(request, userId);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.<CreateAppointmentResponse>builder()
                        .result(response)
                        .build());
    }

    @GetMapping("/{id}")
    public ApiResponse<AppointmentResponse> getAppointment(@PathVariable String id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userId = authentication.getName();
        log.info("GET /appointments/{} - User: {}", id, userId);

        AppointmentResponse response = appointmentService.getAppointment(id);
        validatePermission(response.getPatientUserId(), authentication);

        return ApiResponse.<AppointmentResponse>builder()
                .result(response)
                .build();
    }

    @GetMapping("/{id}/status")
    public ApiResponse<AppointmentStatusResponse> getAppointmentStatus(@PathVariable String id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userId = authentication.getName();
        log.info("GET /appointments/{}/status - User: {}", id, userId);

        AppointmentResponse appointmentResponse = appointmentService.getAppointment(id);
        validatePermission(appointmentResponse.getPatientUserId(), authentication);

        AppointmentStatusResponse response = appointmentService.getAppointmentStatus(id);

        return ApiResponse.<AppointmentStatusResponse>builder()
                .result(response)
                .build();
    }

    @GetMapping("/my")
    public ApiResponse<Page<AppointmentResponse>> getMyAppointments(Pageable pageable) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("GET /appointments/my - User: {}", userId);

        Page<AppointmentResponse> response = appointmentService.getMyAppointments(userId, pageable);

        return ApiResponse.<Page<AppointmentResponse>>builder()
                .result(response)
                .build();
    }

    @GetMapping("/doctor/{doctorId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR')")
    public ApiResponse<Page<AppointmentResponse>> getDoctorAppointments(
            @PathVariable String doctorId,
            Pageable pageable) {

        log.info("GET /appointments/doctor/{} - Fetching doctor appointments", doctorId);

        Page<AppointmentResponse> response = appointmentService.getDoctorAppointments(doctorId, pageable);

        return ApiResponse.<Page<AppointmentResponse>>builder()
                .result(response)
                .build();
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<AppointmentResponse>> cancelAppointment(
            @PathVariable String id,
            @RequestBody @Valid CancelAppointmentRequest request) {

        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("POST /appointments/{}/cancel - User: {}", id, userId);

        AppointmentResponse response = appointmentService.cancelAppointment(id, request, userId);

        return ResponseEntity
                .status(HttpStatus.OK)
                .body(ApiResponse.<AppointmentResponse>builder()
                        .result(response)
                        .build());
    }

    private void validatePermission(String patientUserId, Authentication authentication) {
        String userId = authentication.getName();
        boolean isOwner = patientUserId.equals(userId);
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()));

        if (!isOwner && !isAdmin) {
            throw new AppointmentAccessDeniedException("Unauthorized to access this appointment");
        }
    }
}
