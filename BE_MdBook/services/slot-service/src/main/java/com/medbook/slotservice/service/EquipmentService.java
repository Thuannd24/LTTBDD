package com.medbook.slotservice.service;

import com.medbook.slotservice.dto.request.CreateEquipmentRequest;
import com.medbook.slotservice.dto.request.UpdateEquipmentRequest;
import com.medbook.slotservice.dto.response.EquipmentResponse;
import com.medbook.slotservice.entity.Equipment;
import com.medbook.slotservice.entity.Room;
import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.repository.EquipmentRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EquipmentService {

    private final EquipmentRepository equipmentRepository;
    private final RoomService roomService;

    @Transactional
    public EquipmentResponse createEquipment(CreateEquipmentRequest request) {
        Room room = roomService.findRoom(request.getRoomId());
        if (equipmentRepository.existsByFacilityIdAndEquipmentCode(room.getFacilityId(), request.getEquipmentCode())) {
            throw new AppException(ErrorCode.EQUIPMENT_CODE_ALREADY_EXISTS);
        }

        Equipment equipment = Equipment.builder()
                .id(UUID.randomUUID().toString())
                .equipmentCode(request.getEquipmentCode())
                .equipmentName(request.getEquipmentName())
                .facilityId(room.getFacilityId())
                .roomId(room.getId())
                .equipmentType(request.getEquipmentType())
                .status(EquipmentStatus.ACTIVE)
                .notes(request.getNotes())
                .build();

        return toResponse(equipmentRepository.save(equipment));
    }

    public EquipmentResponse getEquipment(String equipmentId) {
        return toResponse(findEquipment(equipmentId));
    }

    public List<EquipmentResponse> listEquipments(Long facilityId, String roomId) {
        return equipmentRepository.findAll().stream()
                .filter(equipment -> facilityId == null || equipment.getFacilityId().equals(facilityId))
                .filter(equipment -> roomId == null || equipment.getRoomId().equals(roomId))
                .map(this::toResponse)
                .toList();
    }

    public List<EquipmentResponse> listEquipmentsByRoom(String roomId) {
        roomService.findRoom(roomId);
        return equipmentRepository.findByRoomIdAndStatus(roomId, EquipmentStatus.ACTIVE).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public EquipmentResponse updateEquipment(String equipmentId, UpdateEquipmentRequest request) {
        Equipment equipment = findEquipment(equipmentId);
        equipment.setEquipmentName(request.getEquipmentName());
        equipment.setEquipmentType(request.getEquipmentType());
        equipment.setStatus(request.getStatus());
        equipment.setNotes(request.getNotes());
        return toResponse(equipmentRepository.save(equipment));
    }

    @Transactional
    public void deleteEquipment(String equipmentId) {
        equipmentRepository.delete(findEquipment(equipmentId));
    }

    public Equipment findEquipment(String equipmentId) {
        return equipmentRepository.findById(equipmentId)
                .orElseThrow(() -> new AppException(ErrorCode.EQUIPMENT_NOT_FOUND));
    }

    private EquipmentResponse toResponse(Equipment equipment) {
        return EquipmentResponse.builder()
                .id(equipment.getId())
                .equipmentCode(equipment.getEquipmentCode())
                .equipmentName(equipment.getEquipmentName())
                .facilityId(equipment.getFacilityId())
                .roomId(equipment.getRoomId())
                .equipmentType(equipment.getEquipmentType())
                .status(equipment.getStatus())
                .notes(equipment.getNotes())
                .createdAt(equipment.getCreatedAt())
                .updatedAt(equipment.getUpdatedAt())
                .build();
    }
}
