package com.medbook.slotservice.service;

import com.medbook.slotservice.entity.RecurringSlotConfig;
import com.medbook.slotservice.entity.Slot;
import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.repository.SlotRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SlotGeneratorService {

    private final SlotRepository slotRepository;

    public int generateSlotsForNextDays(RecurringSlotConfig config, int days) {
        List<Slot> slots = new ArrayList<>();
        LocalDate today = LocalDate.now();

        for (int i = 0; i < days; i++) {
            LocalDate date = today.plusDays(i);
            if (date.getDayOfWeek() != config.getDayOfWeek()) {
                continue;
            }

            LocalDateTime cursor = date.atTime(config.getStartTime());
            LocalDateTime endBoundary = date.atTime(config.getEndTime());

            while (cursor.plusMinutes(config.getSlotDurationMinutes()).compareTo(endBoundary) <= 0) {
                LocalDateTime slotEnd = cursor.plusMinutes(config.getSlotDurationMinutes());
                boolean exists = slotRepository.existsByTargetTypeAndTargetIdAndStartTimeAndEndTime(
                        config.getTargetType(),
                        config.getTargetId(),
                        cursor,
                        slotEnd);
                if (!exists) {
                    slots.add(Slot.builder()
                            .targetType(config.getTargetType())
                            .targetId(config.getTargetId())
                            .facilityId(config.getFacilityId())
                            .startTime(cursor)
                            .endTime(slotEnd)
                            .status(SlotStatus.AVAILABLE)
                            .recurringConfigId(config.getId())
                            .build());
                }
                cursor = slotEnd;
            }
        }

        if (!slots.isEmpty()) {
            slotRepository.saveAll(slots);
        }
        return slots.size();
    }
}
