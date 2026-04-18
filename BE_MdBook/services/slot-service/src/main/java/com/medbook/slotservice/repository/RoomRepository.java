package com.medbook.slotservice.repository;

import com.medbook.slotservice.entity.Room;
import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RoomRepository extends JpaRepository<Room, String> {

    boolean existsByFacilityIdAndRoomCode(Long facilityId, String roomCode);

    List<Room> findByFacilityIdAndRoomCategoryAndStatus(Long facilityId, RoomCategory roomCategory, RoomStatus status);

    List<Room> findByFacilityIdAndStatus(Long facilityId, RoomStatus status);
}
