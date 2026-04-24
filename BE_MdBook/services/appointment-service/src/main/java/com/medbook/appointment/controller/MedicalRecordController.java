package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.request.CreateMedicalRecordRequest;
import com.medbook.appointment.dto.response.MedicalRecordResponse;
import com.medbook.appointment.service.MedicalRecordService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/medical-records")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class MedicalRecordController {

    MedicalRecordService medicalRecordService;

    /**
     * Bác sĩ tạo / cập nhật kết quả khám sau khi đánh dấu COMPLETED
     */
    @PostMapping("/appointment/{appointmentId}")
    @PreAuthorize("hasRole('DOCTOR')")
    public ApiResponse<MedicalRecordResponse> createRecord(
            @PathVariable String appointmentId,
            @RequestBody CreateMedicalRecordRequest request) {

        String doctorId = SecurityContextHolder.getContext().getAuthentication().getName();
        log.info("Doctor {} creating medical record for appointment {}", doctorId, appointmentId);

        return ApiResponse.<MedicalRecordResponse>builder()
                .result(medicalRecordService.createRecord(appointmentId, request, doctorId))
                .build();
    }

    /**
     * Bệnh nhân hoặc Bác sĩ xem kết quả theo appointment
     */
    @GetMapping("/appointment/{appointmentId}")
    public ApiResponse<MedicalRecordResponse> getByAppointment(@PathVariable String appointmentId) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<MedicalRecordResponse>builder()
                .result(medicalRecordService.getByAppointmentId(appointmentId, userId))
                .build();
    }

    /**
     * Bệnh nhân xem toàn bộ hồ sơ của mình
     */
    @GetMapping("/my")
    public ApiResponse<List<MedicalRecordResponse>> getMyRecords() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<List<MedicalRecordResponse>>builder()
                .result(medicalRecordService.getMyRecords(userId))
                .build();
    }

    /**
     * Bác sĩ xem danh sách hồ sơ mình đã tạo
     */
    @GetMapping("/doctor")
    @PreAuthorize("hasRole('DOCTOR')")
    public ApiResponse<List<MedicalRecordResponse>> getDoctorRecords() {
        String doctorId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ApiResponse.<List<MedicalRecordResponse>>builder()
                .result(medicalRecordService.getDoctorRecords(doctorId))
                .build();
    }
}
