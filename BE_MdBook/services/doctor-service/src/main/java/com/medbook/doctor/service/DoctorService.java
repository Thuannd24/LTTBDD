package com.medbook.doctor.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.medbook.doctor.dto.request.DoctorRequest;
import com.medbook.doctor.dto.response.DoctorResponse;
import com.medbook.doctor.entity.Doctor;
import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import com.medbook.doctor.mapper.DoctorMapper;
import com.medbook.doctor.repository.DoctorRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class DoctorService {
    DoctorRepository doctorRepository;
    DoctorMapper doctorMapper;

    public DoctorResponse createDoctor(DoctorRequest request) {
        doctorRepository.findByUserId(request.getUserId()).ifPresent(doctor -> {
            throw new AppException(ErrorCode.USER_EXISTED);
        });

        Doctor doctor = doctorMapper.toDoctor(request);
        doctor = doctorRepository.save(doctor);

        return doctorMapper.toDoctorResponse(doctor);
    }

    public List<DoctorResponse> getAllDoctors() {
        return doctorRepository.findAll().stream()
                .map(doctorMapper::toDoctorResponse)
                .toList();
    }

    public DoctorResponse getDoctor(String id) {
        return doctorMapper.toDoctorResponse(doctorRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.DOCTOR_NOT_EXISTED)));
    }

    public DoctorResponse getDoctorByUserId(String userId) {
        return doctorMapper.toDoctorResponse(doctorRepository.findByUserId(userId)
                .orElseThrow(() -> new AppException(ErrorCode.DOCTOR_NOT_EXISTED)));
    }

    public DoctorResponse updateDoctor(String id, DoctorRequest request) {
        Doctor doctor = doctorRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.DOCTOR_NOT_EXISTED));

        doctorMapper.updateDoctor(doctor, request);
        return doctorMapper.toDoctorResponse(doctorRepository.save(doctor));
    }

    public void deleteDoctor(String id) {
        doctorRepository.deleteById(id);
    }
}
