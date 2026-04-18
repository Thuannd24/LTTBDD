package com.medbook.slotservice.dto.response;

import com.medbook.slotservice.entity.enums.RecurringStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.LocalTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RecurringSlotConfigResponse {
    private Long id;
    private SlotTargetType targetType;
    private String targetId;
    private Long facilityId;
    private DayOfWeek dayOfWeek;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer slotDurationMinutes;
    private RecurringStatus status;
    private LocalDateTime createdAt;
}
