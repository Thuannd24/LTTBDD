package com.medbook.appointment.mapper;

import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.entity.Appointment;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface AppointmentMapper {
    
    @Mapping(target = "status", source = "status", qualifiedByName = "statusToString")
    AppointmentResponse toResponse(Appointment appointment);
    
    @Mapping(target = "status", source = "status", qualifiedByName = "statusToString")
    AppointmentStatusResponse toStatusResponse(Appointment appointment);
    
    @Named("statusToString")
    static String statusToString(Appointment.AppointmentStatus status) {
        return status != null ? status.toString() : null;
    }
}
