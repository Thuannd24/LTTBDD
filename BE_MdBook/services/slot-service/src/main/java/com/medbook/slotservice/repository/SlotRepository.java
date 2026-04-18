package com.medbook.slotservice.repository;

import com.medbook.slotservice.entity.Slot;
import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface SlotRepository extends JpaRepository<Slot, Long> {

    boolean existsByTargetTypeAndTargetIdAndStartTimeAndEndTime(
            SlotTargetType targetType,
            String targetId,
            LocalDateTime startTime,
            LocalDateTime endTime);

    Page<Slot> findByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThanOrderByStartTimeAsc(
            SlotTargetType targetType,
            Collection<String> targetIds,
            SlotStatus status,
            LocalDateTime startTime,
            LocalDateTime endTime,
            Pageable pageable);

    long countByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThan(
            SlotTargetType targetType,
            Collection<String> targetIds,
            SlotStatus status,
            LocalDateTime startTime,
            LocalDateTime endTime);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM Slot s WHERE s.id = :slotId")
    Optional<Slot> findByIdWithLock(@Param("slotId") Long slotId);

    @Modifying
    @Query("""
        UPDATE Slot s
        SET s.status = :newStatus,
            s.appointmentId = :appointmentId,
            s.updatedAt = CURRENT_TIMESTAMP
        WHERE s.id = :slotId
          AND s.status = 'AVAILABLE'
        """)
    int atomicReserveSlot(
            @Param("slotId") Long slotId,
            @Param("newStatus") SlotStatus newStatus,
            @Param("appointmentId") String appointmentId);
}
