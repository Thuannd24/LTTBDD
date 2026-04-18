package com.medbook.slotservice.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CreateRecurringResult {
    private Long configId;
    private Integer slotsCreated;
}
