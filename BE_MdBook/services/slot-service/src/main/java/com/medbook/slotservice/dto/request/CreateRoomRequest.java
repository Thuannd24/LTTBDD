package com.medbook.slotservice.dto.request;

import com.medbook.slotservice.entity.enums.RoomCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateRoomRequest {

    @NotBlank(message = "roomCode is required")
    private String roomCode;

    @NotBlank(message = "roomName is required")
    private String roomName;

    @NotNull(message = "facilityId is required")
    private Long facilityId;

    @NotNull(message = "roomCategory is required")
    private RoomCategory roomCategory;

    private String notes;
}
