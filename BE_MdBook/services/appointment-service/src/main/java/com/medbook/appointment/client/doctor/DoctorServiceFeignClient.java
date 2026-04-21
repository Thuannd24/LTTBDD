package com.medbook.appointment.client.doctor;

import com.medbook.appointment.configuration.AuthenticationRequestInterceptor;
import com.medbook.appointment.dto.ApiResponse;
import java.time.LocalDateTime;
import java.util.Set;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(
        name = "doctor-service",
        configuration = AuthenticationRequestInterceptor.class)
public interface DoctorServiceFeignClient {

    @GetMapping("/doctors/{doctorId}")
    ApiResponse<DoctorDetailsResponse> getDoctor(@PathVariable("doctorId") String doctorId);

    @GetMapping("/doctor-schedules/{scheduleId}")
    ApiResponse<DoctorScheduleDetailsResponse> getSchedule(@PathVariable("scheduleId") String scheduleId);

    @PostMapping("/doctor-schedules/{scheduleId}/reserve")
    ApiResponse<DoctorScheduleDetailsResponse> reserveSchedule(
            @PathVariable("scheduleId") Long scheduleId,
            @RequestBody AppointmentReferenceRequest request);

    @PostMapping("/doctor-schedules/{scheduleId}/release")
    ApiResponse<DoctorScheduleDetailsResponse> releaseSchedule(
            @PathVariable("scheduleId") Long scheduleId,
            @RequestBody AppointmentReferenceRequest request);
}

record DoctorDetailsResponse(
        String id,
        String userId,
        Set<String> specialtyIds,
        String status
) {
}

record DoctorScheduleDetailsResponse(
        Long id,
        String doctorId,
        LocalDateTime startTime,
        LocalDateTime endTime,
        String status
) {
}

record AppointmentReferenceRequest(String appointmentId) {
}
