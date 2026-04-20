package com.medbook.doctor.controller;

import java.io.IOException;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.medbook.doctor.dto.ApiResponse;
import com.medbook.doctor.dto.request.SpecialtyRequest;
import com.medbook.doctor.dto.response.SpecialtyResponse;
import com.medbook.doctor.service.SpecialtyService;
import com.medbook.doctor.service.UploadService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/specialties")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class SpecialtyController {
    SpecialtyService specialtyService;
    UploadService uploadService;

    @PostMapping("/upload")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<String> uploadImage(@RequestParam("file") MultipartFile file) throws IOException {
        return ApiResponse.<String>builder()
                .result(uploadService.uploadImage(file, "specialties"))
                .build();
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<SpecialtyResponse> createSpecialty(@RequestBody @Valid SpecialtyRequest request) {
        return ApiResponse.<SpecialtyResponse>builder()
                .result(specialtyService.createSpecialty(request))
                .build();
    }

    @GetMapping
    public ApiResponse<List<SpecialtyResponse>> getAllSpecialties() {
        return ApiResponse.<List<SpecialtyResponse>>builder()
                .result(specialtyService.getAllSpecialties())
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<SpecialtyResponse> getSpecialty(@PathVariable String id) {
        return ApiResponse.<SpecialtyResponse>builder()
                .result(specialtyService.getSpecialty(id))
                .build();
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<SpecialtyResponse> updateSpecialty(
            @PathVariable String id, @RequestBody @Valid SpecialtyRequest request) {
        return ApiResponse.<SpecialtyResponse>builder()
                .result(specialtyService.updateSpecialty(id, request))
                .build();
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteSpecialty(@PathVariable String id) {
        specialtyService.deleteSpecialty(id);
        return ApiResponse.<Void>builder().build();
    }
}
