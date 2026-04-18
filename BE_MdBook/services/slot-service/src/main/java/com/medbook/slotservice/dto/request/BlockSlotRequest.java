package com.medbook.slotservice.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BlockSlotRequest {

    @NotBlank(message = "reason is required")
    private String reason;
}
