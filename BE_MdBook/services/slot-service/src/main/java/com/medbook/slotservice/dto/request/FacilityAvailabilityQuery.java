package com.medbook.slotservice.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import lombok.Data;

@Data
public class FacilityAvailabilityQuery {

    @NotNull(message = "facilityId is required")
    private Long facilityId;

    @NotNull(message = "date is required")
    private LocalDate date;

    @Min(value = 1, message = "limit must be greater than 0")
    private Integer limit = 20;
}
