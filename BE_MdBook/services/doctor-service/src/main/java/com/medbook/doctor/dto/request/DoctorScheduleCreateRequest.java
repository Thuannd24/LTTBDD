package com.medbook.doctor.dto.request;

import java.time.LocalDateTime;

import jakarta.validation.constraints.NotNull;
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
public class DoctorScheduleCreateRequest {

    @NotNull(message = "FACILITY_ID_REQUIRED")
    Long facilityId;

    @NotNull(message = "START_TIME_REQUIRED")
    LocalDateTime startTime;

    @NotNull(message = "END_TIME_REQUIRED")
    LocalDateTime endTime;

    String notes;

    Long roomSlotId;
}
