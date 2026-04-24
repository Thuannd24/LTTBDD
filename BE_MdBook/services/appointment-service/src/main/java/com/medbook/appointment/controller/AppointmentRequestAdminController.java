package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.request.AppointmentRequestConfirmRequest;
import com.medbook.appointment.dto.request.AppointmentRequestRejectRequest;
import com.medbook.appointment.dto.response.AppointmentRequestResponse;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.service.AppointmentRequestService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
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
public class AppointmentRequestAdminController {

    AppointmentRequestService appointmentRequestService;



    @PostMapping("/{id}/confirm")
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR')")
    public ApiResponse<AppointmentResponse> confirmRequest(
            @PathVariable String id,
            @RequestBody @Valid AppointmentRequestConfirmRequest request) {
        String actorUserId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<AppointmentResponse>builder()
                .result(appointmentRequestService.confirmRequest(id, request, actorUserId))
                .build();
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR')")
    public ApiResponse<AppointmentRequestResponse> rejectRequest(
            @PathVariable String id,
            @RequestBody @Valid AppointmentRequestRejectRequest request) {
        String actorUserId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<AppointmentRequestResponse>builder()
                .result(appointmentRequestService.rejectRequest(id, request, actorUserId))
                .build();
    }
}
