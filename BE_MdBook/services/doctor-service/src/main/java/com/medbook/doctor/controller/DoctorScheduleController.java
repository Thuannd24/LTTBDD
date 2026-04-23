package com.medbook.doctor.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.medbook.doctor.dto.ApiResponse;
import com.medbook.doctor.dto.request.DoctorScheduleBlockRequest;
import com.medbook.doctor.dto.request.DoctorScheduleCreateRequest;
import com.medbook.doctor.dto.request.DoctorScheduleReleaseRequest;
import com.medbook.doctor.dto.request.DoctorScheduleReserveRequest;
import com.medbook.doctor.dto.response.DoctorScheduleResponse;
import com.medbook.doctor.service.DoctorScheduleService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class DoctorScheduleController {

    DoctorScheduleService doctorScheduleService;

    @PostMapping("/doctors/{doctorId}/schedules")
    @PreAuthorize("hasAuthority('ROLE_ADMIN') or hasAuthority('ROLE_DOCTOR')")
    public ApiResponse<DoctorScheduleResponse> createSchedule(
            @PathVariable String doctorId,
            @RequestBody @Valid DoctorScheduleCreateRequest request,
            Authentication authentication) {
        doctorScheduleService.validateManagePermission(
                doctorId,
                authentication.getName(),
                authentication.getAuthorities());
        return ApiResponse.<DoctorScheduleResponse>builder()
                .result(doctorScheduleService.createSchedule(doctorId, request))
                .build();
    }

    @GetMapping("/doctors/{doctorId}/schedules")
    public ApiResponse<List<DoctorScheduleResponse>> getSchedulesByDoctor(@PathVariable String doctorId) {
        return ApiResponse.<List<DoctorScheduleResponse>>builder()
                .result(doctorScheduleService.getSchedulesByDoctor(doctorId))
                .build();
    }

    @GetMapping("/doctors/{doctorId}/schedules/available")
    public ApiResponse<List<DoctorScheduleResponse>> getAvailableSchedules(
            @PathVariable String doctorId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Long facilityId) {
        return ApiResponse.<List<DoctorScheduleResponse>>builder()
                .result(doctorScheduleService.getAvailableSchedules(doctorId, date, facilityId))
                .build();
    }

    @GetMapping("/doctor-schedules/{scheduleId}")
    public ApiResponse<DoctorScheduleResponse> getSchedule(@PathVariable Long scheduleId) {
        return ApiResponse.<DoctorScheduleResponse>builder()
                .result(doctorScheduleService.getSchedule(scheduleId))
                .build();
    }

    @PutMapping("/doctor-schedules/{scheduleId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ApiResponse<DoctorScheduleResponse> updateSchedule(
            @PathVariable Long scheduleId,
            @RequestBody @Valid DoctorScheduleCreateRequest request) {
        return ApiResponse.<DoctorScheduleResponse>builder()
                .result(doctorScheduleService.updateSchedule(scheduleId, request))
                .build();
    }

    @DeleteMapping("/doctor-schedules/{scheduleId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ApiResponse<Void> deleteSchedule(@PathVariable Long scheduleId) {
        doctorScheduleService.deleteSchedule(scheduleId);
        return ApiResponse.<Void>builder().build();
    }

    @PostMapping("/doctor-schedules/{scheduleId}/reserve")
    public ApiResponse<DoctorScheduleResponse> reserveSchedule(
            @PathVariable Long scheduleId,
            @RequestBody @Valid DoctorScheduleReserveRequest request) {
        return ApiResponse.<DoctorScheduleResponse>builder()
                .result(doctorScheduleService.reserveSchedule(scheduleId, request))
                .build();
    }

    @PostMapping("/doctor-schedules/{scheduleId}/release")
    public ApiResponse<DoctorScheduleResponse> releaseSchedule(
            @PathVariable Long scheduleId,
            @RequestBody(required = false) DoctorScheduleReleaseRequest request) {
        return ApiResponse.<DoctorScheduleResponse>builder()
                .result(doctorScheduleService.releaseSchedule(
                        scheduleId,
                        request != null ? request.getAppointmentId() : null))
                .build();
    }

    @PostMapping("/doctor-schedules/{scheduleId}/block")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ApiResponse<DoctorScheduleResponse> blockSchedule(
            @PathVariable Long scheduleId,
            @RequestBody DoctorScheduleBlockRequest request) {
        return ApiResponse.<DoctorScheduleResponse>builder()
                .result(doctorScheduleService.blockSchedule(scheduleId, request))
                .build();
    }
}
