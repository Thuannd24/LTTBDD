package com.medbook.slotservice.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.DayOfWeek;
import java.time.LocalTime;
import lombok.Data;

@Data
public class CreateRecurringSlotRequest {

    @NotNull(message = "targetType is required")
    private SlotTargetType targetType;

    @NotBlank(message = "targetId is required")
    private String targetId;

    @NotNull(message = "facilityId is required")
    private Long facilityId;

    @NotNull(message = "dayOfWeek is required")
    private DayOfWeek dayOfWeek;

    @NotNull(message = "startTime is required")
    @JsonFormat(pattern = "HH:mm")
    private LocalTime startTime;

    @NotNull(message = "endTime is required")
    @JsonFormat(pattern = "HH:mm")
    private LocalTime endTime;

    @NotNull(message = "slotDurationMinutes is required")
    @Min(value = 5, message = "slotDurationMinutes must be at least 5")
    private Integer slotDurationMinutes;
}
