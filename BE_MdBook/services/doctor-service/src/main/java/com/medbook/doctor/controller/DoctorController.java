package com.medbook.doctor.controller;

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
import org.springframework.web.bind.annotation.RestController;

import com.medbook.doctor.dto.ApiResponse;
import com.medbook.doctor.dto.request.DoctorRequest;
import com.medbook.doctor.dto.response.DoctorResponse;
import com.medbook.doctor.service.DoctorService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/doctors")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class DoctorController {
    DoctorService doctorService;

    @PostMapping
    @PreAuthorize("hasAuthority('ROLE_ADMIN') or hasAuthority('ROLE_DOCTOR')")
    public ApiResponse<DoctorResponse> createDoctor(@RequestBody @Valid DoctorRequest request) {
        return ApiResponse.<DoctorResponse>builder()
                .result(doctorService.createDoctor(request))
                .build();
    }

    @GetMapping
    public ApiResponse<List<DoctorResponse>> getAllDoctors() {
        return ApiResponse.<List<DoctorResponse>>builder()
                .result(doctorService.getAllDoctors())
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<DoctorResponse> getDoctor(@PathVariable String id) {
        return ApiResponse.<DoctorResponse>builder()
                .result(doctorService.getDoctor(id))
                .build();
    }

    @GetMapping("/user/{userId}")
    public ApiResponse<DoctorResponse> getDoctorByUserId(@PathVariable String userId) {
        return ApiResponse.<DoctorResponse>builder()
                .result(doctorService.getDoctorByUserId(userId))
                .build();
    }

    @PutMapping("/{id}")
    public ApiResponse<DoctorResponse> updateDoctor(
            @PathVariable String id, @RequestBody @Valid DoctorRequest request) {
        return ApiResponse.<DoctorResponse>builder()
                .result(doctorService.updateDoctor(id, request))
                .build();
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteDoctor(@PathVariable String id) {
        doctorService.deleteDoctor(id);
        return ApiResponse.<Void>builder().build();
    }
}
