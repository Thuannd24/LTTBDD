package com.medbook.slotservice.service;

import com.medbook.slotservice.dto.request.CreateRoomRequest;
import com.medbook.slotservice.dto.request.UpdateRoomRequest;
import com.medbook.slotservice.dto.response.RoomResponse;
import com.medbook.slotservice.entity.Room;
import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.repository.EquipmentRepository;
import com.medbook.slotservice.repository.RoomRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RoomService {

    private final RoomRepository roomRepository;
    private final EquipmentRepository equipmentRepository;

    @Transactional
    public RoomResponse createRoom(CreateRoomRequest request) {
        if (roomRepository.existsByFacilityIdAndRoomCode(request.getFacilityId(), request.getRoomCode())) {
            throw new AppException(ErrorCode.ROOM_CODE_ALREADY_EXISTS);
        }

        Room room = Room.builder()
                .id(UUID.randomUUID().toString())
                .roomCode(request.getRoomCode())
                .roomName(request.getRoomName())
                .facilityId(request.getFacilityId())
                .roomCategory(request.getRoomCategory())
                .status(RoomStatus.ACTIVE)
                .notes(request.getNotes())
                .build();

        return toResponse(roomRepository.save(room));
    }

    public RoomResponse getRoom(String roomId) {
        return toResponse(findRoom(roomId));
    }

    public List<RoomResponse> listRooms(Long facilityId, RoomCategory roomCategory, RoomStatus status) {
        return roomRepository.findAll().stream()
                .filter(room -> facilityId == null || room.getFacilityId().equals(facilityId))
                .filter(room -> roomCategory == null || room.getRoomCategory() == roomCategory)
                .filter(room -> status == null || room.getStatus() == status)
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public RoomResponse updateRoom(String roomId, UpdateRoomRequest request) {
        Room room = findRoom(roomId);
        room.setRoomName(request.getRoomName());
        room.setRoomCategory(request.getRoomCategory());
        room.setStatus(request.getStatus());
        room.setNotes(request.getNotes());
        return toResponse(roomRepository.save(room));
    }

    @Transactional
    public void deleteRoom(String roomId) {
        Room room = findRoom(roomId);
        if (equipmentRepository.existsByRoomId(roomId)) {
            throw new AppException(ErrorCode.ROOM_HAS_EQUIPMENTS);
        }
        roomRepository.delete(room);
    }

    public Room findRoom(String roomId) {
        return roomRepository.findById(roomId)
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_NOT_FOUND));
    }

    private RoomResponse toResponse(Room room) {
        return RoomResponse.builder()
                .id(room.getId())
                .roomCode(room.getRoomCode())
                .roomName(room.getRoomName())
                .facilityId(room.getFacilityId())
                .roomCategory(room.getRoomCategory())
                .status(room.getStatus())
                .notes(room.getNotes())
                .createdAt(room.getCreatedAt())
                .updatedAt(room.getUpdatedAt())
                .build();
    }
}
