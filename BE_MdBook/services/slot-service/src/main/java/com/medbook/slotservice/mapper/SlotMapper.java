package com.medbook.slotservice.mapper;

import com.medbook.slotservice.dto.response.SlotResponse;
import com.medbook.slotservice.entity.Slot;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface SlotMapper {
    SlotResponse toResponse(Slot slot);
}
