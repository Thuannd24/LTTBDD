package com.medbook.doctor.dto.response;

import java.time.LocalDateTime;

import com.medbook.doctor.entity.enums.DoctorScheduleStatus;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DoctorScheduleResponse {
    Long id;
    String doctorId;
    Long facilityId;
    LocalDateTime startTime;
    LocalDateTime endTime;
    DoctorScheduleStatus status;
    String appointmentId;
    String notes;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
