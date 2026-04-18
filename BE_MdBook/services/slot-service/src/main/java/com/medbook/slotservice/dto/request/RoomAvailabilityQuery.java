package com.medbook.slotservice.dto.request;

import com.medbook.slotservice.entity.enums.RoomCategory;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import lombok.Data;

@Data
public class RoomAvailabilityQuery {

    @NotNull(message = "facilityId is required")
    private Long facilityId;

    @NotNull(message = "roomCategory is required")
    private RoomCategory roomCategory;

    @NotNull(message = "date is required")
    private LocalDate date;

    @Min(value = 1, message = "limit must be greater than 0")
    private Integer limit = 5;
}
