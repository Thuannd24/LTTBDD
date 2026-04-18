package com.medbook.slotservice.mapper;

import com.medbook.slotservice.dto.response.RecurringSlotConfigResponse;
import com.medbook.slotservice.entity.RecurringSlotConfig;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface RecurringSlotConfigMapper {
    RecurringSlotConfigResponse toResponse(RecurringSlotConfig config);
}
