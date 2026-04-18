package com.medbook.slotservice.dto.request;

import com.medbook.slotservice.entity.enums.EquipmentType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateEquipmentRequest {

    @NotBlank(message = "equipmentCode is required")
    private String equipmentCode;

    @NotBlank(message = "equipmentName is required")
    private String equipmentName;

    @NotBlank(message = "roomId is required")
    private String roomId;

    @NotNull(message = "equipmentType is required")
    private EquipmentType equipmentType;

    private String notes;
}
