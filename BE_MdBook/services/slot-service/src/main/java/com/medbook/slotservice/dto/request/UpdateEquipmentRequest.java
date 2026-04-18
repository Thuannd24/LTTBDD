package com.medbook.slotservice.dto.request;

import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.EquipmentType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateEquipmentRequest {

    @NotBlank(message = "equipmentName is required")
    private String equipmentName;

    @NotNull(message = "equipmentType is required")
    private EquipmentType equipmentType;

    @NotNull(message = "status is required")
    private EquipmentStatus status;

    private String notes;
}
