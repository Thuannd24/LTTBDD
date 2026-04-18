package com.medbook.slotservice.dto.response;

import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SlotResponse {
    private Long id;
    private SlotTargetType targetType;
    private String targetId;
    private Long facilityId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private SlotStatus status;
    private String appointmentId;
    private String notes;
    private Long recurringConfigId;
    private LocalDateTime createdAt;
}
