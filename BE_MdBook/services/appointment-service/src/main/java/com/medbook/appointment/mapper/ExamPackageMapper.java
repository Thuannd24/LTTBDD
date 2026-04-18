package com.medbook.appointment.mapper;

import com.medbook.appointment.dto.request.ExamPackageRequest;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.entity.ExamPackage;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface ExamPackageMapper {
    ExamPackage toEntity(ExamPackageRequest request);
    
    ExamPackageResponse toResponse(ExamPackage entity);
    
    void updateEntity(@MappingTarget ExamPackage entity, ExamPackageRequest request);
}
