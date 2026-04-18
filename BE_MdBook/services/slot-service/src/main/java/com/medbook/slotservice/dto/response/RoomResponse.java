package com.medbook.slotservice.dto.response;

import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RoomResponse {
    private String id;
    private String roomCode;
    private String roomName;
    private Long facilityId;
    private RoomCategory roomCategory;
    private RoomStatus status;
    private String notes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
