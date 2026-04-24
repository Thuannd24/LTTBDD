package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.request.AppointmentRequestCreateRequest;
import com.medbook.appointment.dto.response.AppointmentRequestResponse;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.service.AppointmentRequestService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/appointment-requests")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class AppointmentRequestController {

    AppointmentRequestService appointmentRequestService;

    @PostMapping
    public ResponseEntity<ApiResponse<AppointmentRequestResponse>> createAppointmentRequest(
            @RequestBody @Valid AppointmentRequestCreateRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        AppointmentRequestResponse response = appointmentRequestService.createRequest(request, userId);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<AppointmentRequestResponse>builder().result(response).build());
    }

    @GetMapping("/pending")
    @org.springframework.security.access.prepost.PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR')")
    public ApiResponse<Page<AppointmentRequestResponse>> getPendingRequests(Pageable pageable) {
        return ApiResponse.<Page<AppointmentRequestResponse>>builder()
                .result(appointmentRequestService.getPendingRequests(pageable))
                .build();
    }

    @GetMapping("/my")
    public ApiResponse<Page<AppointmentRequestResponse>> getMyRequests(Pageable pageable) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<Page<AppointmentRequestResponse>>builder()
                .result(appointmentRequestService.getMyRequests(userId, pageable))
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<AppointmentRequestResponse> getRequest(@PathVariable String id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        AppointmentRequestResponse response = appointmentRequestService.getRequest(id);
        validatePermission(response.getPatientUserId(), authentication);

        return ApiResponse.<AppointmentRequestResponse>builder().result(response).build();
    }

    @PostMapping("/{id}/cancel")
    public ApiResponse<AppointmentRequestResponse> cancelRequest(@PathVariable String id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<AppointmentRequestResponse>builder()
                .result(appointmentRequestService.cancelRequest(id, userId))
                .build();
    }

    private void validatePermission(String patientUserId, Authentication authentication) {
        String userId = authentication.getName();
        boolean isOwner = patientUserId.equals(userId);
        boolean isAdminOrDoctor = authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority())
                        || "ROLE_DOCTOR".equals(authority.getAuthority()));

        if (!isOwner && !isAdminOrDoctor) {
            throw new AppointmentAccessDeniedException("Unauthorized to access this appointment request");
        }
    }
}
