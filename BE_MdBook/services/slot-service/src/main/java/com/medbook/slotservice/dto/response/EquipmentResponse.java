package com.medbook.slotservice.dto.response;

import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.EquipmentType;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class EquipmentResponse {
    private String id;
    private String equipmentCode;
    private String equipmentName;
    private Long facilityId;
    private String roomId;
    private EquipmentType equipmentType;
    private EquipmentStatus status;
    private String notes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
