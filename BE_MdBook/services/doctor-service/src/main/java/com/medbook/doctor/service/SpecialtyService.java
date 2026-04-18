package com.medbook.doctor.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import com.medbook.doctor.dto.request.SpecialtyRequest;
import com.medbook.doctor.dto.response.SpecialtyResponse;
import com.medbook.doctor.entity.Specialty;
import com.medbook.doctor.mapper.SpecialtyMapper;
import com.medbook.doctor.repository.SpecialtyRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class SpecialtyService {
    SpecialtyRepository specialtyRepository;
    SpecialtyMapper specialtyMapper;

    public SpecialtyResponse createSpecialty(SpecialtyRequest request) {
        if (specialtyRepository.existsByName(request.getName())) {
            throw new AppException(ErrorCode.SPECIALTY_EXISTED);
        }

        Specialty specialty = specialtyMapper.toSpecialty(request);
        specialty = specialtyRepository.save(specialty);
        return specialtyMapper.toSpecialtyResponse(specialty);
    }

    public List<SpecialtyResponse> getAllSpecialties() {
        return specialtyRepository.findAll().stream()
                .map(specialtyMapper::toSpecialtyResponse)
                .toList();
    }

    public SpecialtyResponse getSpecialty(String id) {
        return specialtyMapper.toSpecialtyResponse(specialtyRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.SPECIALTY_NOT_EXISTED)));
    }

    public SpecialtyResponse updateSpecialty(String id, SpecialtyRequest request) {
        Specialty specialty = specialtyRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.SPECIALTY_NOT_EXISTED));

        if (specialtyRepository.existsByNameAndIdNot(request.getName(), id)) {
            throw new AppException(ErrorCode.SPECIALTY_EXISTED);
        }

        specialtyMapper.updateSpecialty(specialty, request);
        return specialtyMapper.toSpecialtyResponse(specialtyRepository.save(specialty));
    }

    public void deleteSpecialty(String id) {
        specialtyRepository.deleteById(id);
    }
}
