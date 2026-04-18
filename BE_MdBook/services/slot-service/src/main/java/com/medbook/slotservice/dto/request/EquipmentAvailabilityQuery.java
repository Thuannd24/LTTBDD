package com.medbook.slotservice.dto.request;

import com.medbook.slotservice.entity.enums.EquipmentType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import lombok.Data;

@Data
public class EquipmentAvailabilityQuery {

    @NotNull(message = "facilityId is required")
    private Long facilityId;

    @NotBlank(message = "roomId is required")
    private String roomId;

    private EquipmentType equipmentType;

    @NotNull(message = "date is required")
    private LocalDate date;

    @Min(value = 1, message = "limit must be greater than 0")
    private Integer limit = 5;
}
