package com.medbook.slotservice.dto.request;

import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateRoomRequest {

    @NotBlank(message = "roomName is required")
    private String roomName;

    @NotNull(message = "roomCategory is required")
    private RoomCategory roomCategory;

    @NotNull(message = "status is required")
    private RoomStatus status;

    private String notes;
}
