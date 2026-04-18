package com.medbook.doctor.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

import com.medbook.doctor.dto.request.DoctorRequest;
import com.medbook.doctor.dto.response.DoctorResponse;
import com.medbook.doctor.entity.Doctor;

@Mapper(componentModel = "spring")
public interface DoctorMapper {
    Doctor toDoctor(DoctorRequest request);

    DoctorResponse toDoctorResponse(Doctor doctor);

    void updateDoctor(@MappingTarget Doctor doctor, DoctorRequest request);
}
