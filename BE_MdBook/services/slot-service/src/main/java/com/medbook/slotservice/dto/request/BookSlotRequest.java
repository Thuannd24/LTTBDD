package com.medbook.slotservice.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class BookSlotRequest {

    @NotNull(message = "appointmentId is required")
    private String appointmentId;
}
