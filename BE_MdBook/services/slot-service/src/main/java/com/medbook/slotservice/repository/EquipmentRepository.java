package com.medbook.slotservice.repository;

import com.medbook.slotservice.entity.Equipment;
import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.EquipmentType;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EquipmentRepository extends JpaRepository<Equipment, String> {

    boolean existsByFacilityIdAndEquipmentCode(Long facilityId, String equipmentCode);

    boolean existsByRoomId(String roomId);

    List<Equipment> findByRoomIdAndStatus(String roomId, EquipmentStatus status);

    List<Equipment> findByRoomIdAndEquipmentTypeAndStatus(String roomId, EquipmentType equipmentType, EquipmentStatus status);
}
