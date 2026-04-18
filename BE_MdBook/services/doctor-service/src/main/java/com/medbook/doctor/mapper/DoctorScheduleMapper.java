package com.medbook.doctor.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import com.medbook.doctor.dto.request.DoctorScheduleCreateRequest;
import com.medbook.doctor.dto.response.DoctorScheduleResponse;
import com.medbook.doctor.entity.DoctorSchedule;

@Mapper(componentModel = "spring")
public interface DoctorScheduleMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "doctorId", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "appointmentId", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    DoctorSchedule toDoctorSchedule(DoctorScheduleCreateRequest request);

    DoctorScheduleResponse toDoctorScheduleResponse(DoctorSchedule doctorSchedule);
}
