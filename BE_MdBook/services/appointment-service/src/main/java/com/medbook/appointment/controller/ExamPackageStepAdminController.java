package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.request.ExamPackageStepRequest;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.service.ExamPackageStepService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Admin API endpoints cho ExamPackageStep CRUD
 */
@RestController
@RequestMapping("/admin/exam-packages/{packageId}/steps")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ExamPackageStepAdminController {
    
    ExamPackageStepService stepService;
    
    /**
     * POST /admin/exam-packages/{packageId}/steps
     * Tạo step mới cho package
     */
    @PostMapping
    public ApiResponse<ExamPackageStepResponse> createStep(
            @PathVariable String packageId,
            @Valid @RequestBody ExamPackageStepRequest request) {
        return ApiResponse.<ExamPackageStepResponse>builder()
                .result(stepService.createStep(packageId, request))
                .build();
    }
    
    /**
     * PUT /admin/exam-packages/{packageId}/steps/{stepId}
     * Cập nhật step
     */
    @PutMapping("/{stepId}")
    public ApiResponse<ExamPackageStepResponse> updateStep(
            @PathVariable String packageId,
            @PathVariable String stepId,
            @Valid @RequestBody ExamPackageStepRequest request) {
        return ApiResponse.<ExamPackageStepResponse>builder()
                .result(stepService.updateStep(packageId, stepId, request))
                .build();
    }
    
    /**
     * DELETE /admin/exam-packages/{packageId}/steps/{stepId}
     * Xóa step
     */
    @DeleteMapping("/{stepId}")
    public ApiResponse<Void> deleteStep(
            @PathVariable String packageId,
            @PathVariable String stepId) {
        stepService.deleteStep(packageId, stepId);
        return ApiResponse.<Void>builder()
                .result(null)
                .build();
    }
    
}
