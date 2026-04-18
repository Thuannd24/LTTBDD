package com.medbook.slotservice.repository;

import com.medbook.slotservice.entity.RecurringSlotConfig;
import com.medbook.slotservice.entity.enums.RecurringStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RecurringSlotConfigRepository extends JpaRepository<RecurringSlotConfig, Long> {

    boolean existsByTargetTypeAndTargetIdAndFacilityIdAndDayOfWeekAndStartTimeAndEndTime(
            SlotTargetType targetType,
            String targetId,
            Long facilityId,
            DayOfWeek dayOfWeek,
            LocalTime startTime,
            LocalTime endTime);

    List<RecurringSlotConfig> findByTargetTypeAndTargetIdAndStatus(
            SlotTargetType targetType,
            String targetId,
            RecurringStatus status);

    List<RecurringSlotConfig> findByFacilityIdAndStatus(Long facilityId, RecurringStatus status);
}
