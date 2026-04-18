package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.request.ExamPackageRequest;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.service.ExamPackageService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Admin API endpoints cho ExamPackage CRUD
 */
@RestController
@RequestMapping("/admin/exam-packages")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ExamPackageAdminController {
    
    ExamPackageService packageService;
    
    /**
     * POST /admin/exam-packages
     * Tạo package mới
     */
    @PostMapping
    public ApiResponse<ExamPackageResponse> createPackage(@Valid @RequestBody ExamPackageRequest request) {
        return ApiResponse.<ExamPackageResponse>builder()
                .result(packageService.createPackage(request))
                .build();
    }
    
    /**
     * PUT /admin/exam-packages/{id}
     * Cập nhật package
     */
    @PutMapping("/{id}")
    public ApiResponse<ExamPackageResponse> updatePackage(
            @PathVariable String id,
            @Valid @RequestBody ExamPackageRequest request) {
        return ApiResponse.<ExamPackageResponse>builder()
                .result(packageService.updatePackage(id, request))
                .build();
    }
    
    /**
     * DELETE /admin/exam-packages/{id}
     * Xóa package
     */
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deletePackage(@PathVariable String id) {
        packageService.deletePackage(id);
        return ApiResponse.<Void>builder()
                .result(null)
                .build();
    }
}
