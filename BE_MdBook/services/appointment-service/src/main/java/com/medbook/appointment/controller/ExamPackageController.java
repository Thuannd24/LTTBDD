package com.medbook.appointment.controller;

import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.service.ExamPackageService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Public API endpoints cho ExamPackage (READ only)
 */
@RestController
@RequestMapping("/exam-packages")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ExamPackageController {
    
    ExamPackageService packageService;
    
    /**
     * GET /exam-packages
     * Lấy danh sách tất cả packages (có phân trang)
     */
    @GetMapping
    public ApiResponse<Page<ExamPackageResponse>> getAllPackages(Pageable pageable) {
        return ApiResponse.<Page<ExamPackageResponse>>builder()
                .result(packageService.getAllPackages(pageable))
                .build();
    }
    
    /**
     * GET /exam-packages/{id}
     * Lấy chi tiết 1 package theo ID
     */
    @GetMapping("/{id}")
    public ApiResponse<ExamPackageResponse> getPackageById(@PathVariable String id) {
        return ApiResponse.<ExamPackageResponse>builder()
                .result(packageService.getPackageById(id))
                .build();
    }
    
}
