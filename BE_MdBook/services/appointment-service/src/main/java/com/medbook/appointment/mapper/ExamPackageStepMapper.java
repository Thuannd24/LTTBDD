package com.medbook.appointment.mapper;

import com.medbook.appointment.dto.request.ExamPackageStepRequest;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.entity.ExamPackageStep;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface ExamPackageStepMapper {
    ExamPackageStep toEntity(ExamPackageStepRequest request);
    
    ExamPackageStepResponse toResponse(ExamPackageStep entity);
    
    void updateEntity(@MappingTarget ExamPackageStep entity, ExamPackageStepRequest request);
}
