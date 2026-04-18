package com.medbook.doctor.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

import com.medbook.doctor.dto.request.SpecialtyRequest;
import com.medbook.doctor.dto.response.SpecialtyResponse;
import com.medbook.doctor.entity.Specialty;

@Mapper(componentModel = "spring")
public interface SpecialtyMapper {
    Specialty toSpecialty(SpecialtyRequest request);

    SpecialtyResponse toSpecialtyResponse(Specialty specialty);

    void updateSpecialty(@MappingTarget Specialty specialty, SpecialtyRequest request);
}
