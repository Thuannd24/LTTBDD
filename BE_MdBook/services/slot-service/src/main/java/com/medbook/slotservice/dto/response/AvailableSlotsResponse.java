package com.medbook.slotservice.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AvailableSlotsResponse {
    private List<SlotResponse> slots;
    private Integer totalAvailable;
    private Boolean hasMore;
}
