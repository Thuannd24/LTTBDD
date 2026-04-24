package com.medbook.slotservice.service;

import com.medbook.slotservice.dto.request.BlockSlotRequest;
import com.medbook.slotservice.dto.request.BookSlotRequest;
import com.medbook.slotservice.dto.request.CreateRecurringSlotRequest;
import com.medbook.slotservice.dto.response.AvailableSlotsResponse;
import com.medbook.slotservice.dto.response.CreateRecurringResult;
import com.medbook.slotservice.dto.response.RecurringSlotConfigResponse;
import com.medbook.slotservice.dto.response.SlotResponse;
import com.medbook.slotservice.entity.RecurringSlotConfig;
import com.medbook.slotservice.entity.Slot;
import com.medbook.slotservice.entity.SlotHistory;
import com.medbook.slotservice.entity.enums.RecurringStatus;
import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.mapper.RecurringSlotConfigMapper;
import com.medbook.slotservice.mapper.SlotMapper;
import com.medbook.slotservice.repository.RecurringSlotConfigRepository;
import com.medbook.slotservice.repository.SlotHistoryRepository;
import com.medbook.slotservice.repository.SlotRepository;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class SlotService {

    private static final int GENERATE_DAYS = 30;

    private final SlotRepository slotRepository;
    private final RecurringSlotConfigRepository recurringRepository;
    private final SlotHistoryRepository historyRepository;
    private final SlotMapper slotMapper;
    private final RecurringSlotConfigMapper recurringMapper;
    private final SlotCacheService cacheService;
    private final SlotGeneratorService generatorService;

    @Transactional
    public CreateRecurringResult createRecurringSlots(CreateRecurringSlotRequest request) {
        validateRecurringRequest(request);
        assertTargetExists(request.getTargetType(), request.getTargetId(), request.getFacilityId());

        boolean exists = recurringRepository
                .existsByTargetTypeAndTargetIdAndFacilityIdAndDayOfWeekAndStartTimeAndEndTime(
                        request.getTargetType(),
                        request.getTargetId(),
                        request.getFacilityId(),
                        request.getDayOfWeek(),
                        request.getStartTime(),
                        request.getEndTime());
        if (exists) {
            throw new AppException(ErrorCode.RECURRING_CONFIG_ALREADY_EXISTS);
        }

        RecurringSlotConfig config = RecurringSlotConfig.builder()
                .targetType(request.getTargetType())
                .targetId(request.getTargetId())
                .facilityId(request.getFacilityId())
                .dayOfWeek(request.getDayOfWeek())
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .slotDurationMinutes(request.getSlotDurationMinutes())
                .status(RecurringStatus.ACTIVE)
                .build();

        config = recurringRepository.save(config);
        int slotsCreated = generatorService.generateSlotsForNextDays(config, GENERATE_DAYS);
        invalidateTargetAvailability(config.getTargetType(), config.getTargetId(), config.getFacilityId());

        return CreateRecurringResult.builder()
                .configId(config.getId())
                .slotsCreated(slotsCreated)
                .build();
    }

    public List<RecurringSlotConfigResponse> getScheduleConfigs(SlotTargetType targetType, String targetId,
            Long facilityId) {
        if (targetType != null && targetId != null && !targetId.isBlank()) {
            return recurringRepository
                    .findByTargetTypeAndTargetIdAndStatus(targetType, targetId, RecurringStatus.ACTIVE)
                    .stream()
                    .map(recurringMapper::toResponse)
                    .toList();
        }

        return recurringRepository.findByFacilityIdAndStatus(facilityId, RecurringStatus.ACTIVE)
                .stream()
                .map(recurringMapper::toResponse)
                .toList();
    }

    public SlotResponse getSlot(Long slotId) {
        Slot slot = slotRepository.findById(slotId)
                .orElseThrow(() -> new AppException(ErrorCode.SLOT_NOT_FOUND));
        return slotMapper.toResponse(slot);
    }

    public AvailableSlotsResponse findAvailableFacilitySlots(com.medbook.slotservice.dto.request.FacilityAvailabilityQuery query) {
        LocalDateTime startOfDay = query.getDate().atStartOfDay();
        LocalDateTime endOfDay = query.getDate().atTime(23, 59, 59);
        int limit = query.getLimit() != null ? query.getLimit() : 20;

        List<SlotResponse> responses = slotRepository
                .findByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThanOrderByStartTimeAsc(
                        SlotTargetType.FACILITY,
                        List.of(String.valueOf(query.getFacilityId())),
                        SlotStatus.AVAILABLE,
                        startOfDay,
                        endOfDay,
                        org.springframework.data.domain.PageRequest.of(0, limit))
                .stream()
                .map(slotMapper::toResponse)
                .toList();

        long total = slotRepository
                .countByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThan(
                        SlotTargetType.FACILITY,
                        List.of(String.valueOf(query.getFacilityId())),
                        SlotStatus.AVAILABLE,
                        startOfDay,
                        endOfDay);

        return buildAvailableResponse(responses, (int) total, total > limit);
    }

    @Transactional
    public SlotResponse reserveSlot(Long slotId, BookSlotRequest request) {
        Slot slot = slotRepository.findByIdWithLock(slotId)
                .orElseThrow(() -> new AppException(ErrorCode.SLOT_NOT_FOUND));

        if (slot.getStatus() != SlotStatus.AVAILABLE) {
            throw new AppException(ErrorCode.SLOT_ALREADY_RESERVED);
        }

        int updated = slotRepository.atomicReserveSlot(slotId, SlotStatus.RESERVED, request.getAppointmentId());
        if (updated == 0) {
            throw new AppException(ErrorCode.SLOT_ALREADY_RESERVED);
        }

        slot = slotRepository.findById(slotId).orElseThrow(() -> new AppException(ErrorCode.SLOT_NOT_FOUND));
        recordHistory(slotId, SlotStatus.AVAILABLE, SlotStatus.RESERVED, request.getAppointmentId(),
                "Reserved by appointment");
        invalidateBySlot(slot);

        return slotMapper.toResponse(slot);
    }

    @Transactional
    public SlotResponse releaseSlot(Long slotId) {
        return releaseSlot(slotId, null);
    }

    @Transactional
    public SlotResponse releaseSlot(Long slotId, String appointmentId) {
        Slot slot = slotRepository.findByIdWithLock(slotId)
                .orElseThrow(() -> new AppException(ErrorCode.SLOT_NOT_FOUND));

        if (slot.getStatus() != SlotStatus.RESERVED) {
            throw new AppException(ErrorCode.SLOT_NOT_RESERVED);
        }

        if (appointmentId != null && !appointmentId.equals(slot.getAppointmentId())) {
            throw new AppException(ErrorCode.SLOT_APPOINTMENT_MISMATCH);
        }

        String reservedAppointmentId = slot.getAppointmentId();
        slot.setStatus(SlotStatus.AVAILABLE);
        slot.setAppointmentId(null);
        slot = slotRepository.save(slot);

        recordHistory(slotId, SlotStatus.RESERVED, SlotStatus.AVAILABLE, reservedAppointmentId,
                "Released by appointment cancellation");
        invalidateBySlot(slot);

        return slotMapper.toResponse(slot);
    }

    @Transactional
    public SlotResponse blockSlot(Long slotId, BlockSlotRequest request) {
        Slot slot = slotRepository.findById(slotId)
                .orElseThrow(() -> new AppException(ErrorCode.SLOT_NOT_FOUND));

        if (slot.getStatus() == SlotStatus.RESERVED) {
            throw new AppException(ErrorCode.SLOT_CANNOT_BLOCK);
        }

        SlotStatus previousStatus = slot.getStatus();
        slot.setStatus(SlotStatus.BLOCKED);
        slot.setNotes(request.getReason());
        slot = slotRepository.save(slot);

        recordHistory(slotId, previousStatus, SlotStatus.BLOCKED, null, request.getReason());
        invalidateBySlot(slot);

        return slotMapper.toResponse(slot);
    }

    public List<SlotHistory> getSlotHistory(Long slotId) {
        if (!slotRepository.existsById(slotId)) {
            throw new AppException(ErrorCode.SLOT_NOT_FOUND);
        }
        return historyRepository.findBySlotIdOrderByChangedAtDesc(slotId);
    }

    private void validateRecurringRequest(CreateRecurringSlotRequest request) {
        if (!request.getStartTime().isBefore(request.getEndTime())) {
            throw new AppException(ErrorCode.INVALID_TIME_RANGE);
        }
        if (request.getSlotDurationMinutes() == null || request.getSlotDurationMinutes() <= 0) {
            throw new AppException(ErrorCode.INVALID_SLOT_DURATION);
        }
    }

    private void assertTargetExists(SlotTargetType targetType, String targetId, Long facilityId) {
        if (targetType == SlotTargetType.DOCTOR) {
            // Doctors are managed by profile-service/auth-service
            // We just assume the targetId is valid for now
            return;
        }

        if (targetType == SlotTargetType.FACILITY) {
            // Facility is implicitly valid if it matches facilityId
            if (targetId != null && !targetId.equals(String.valueOf(facilityId))) {
                throw new AppException(ErrorCode.TARGET_NOT_FOUND);
            }
            return;
        }

        throw new AppException(ErrorCode.INVALID_TARGET_TYPE);
    }

    private void invalidateBySlot(Slot slot) {
        invalidateTargetAvailability(slot.getTargetType(), slot.getTargetId(), slot.getFacilityId());
    }

    private void invalidateTargetAvailability(SlotTargetType targetType, String targetId, Long facilityId) {
        if (targetType == SlotTargetType.DOCTOR) {
            // No specific cache for doctor availability yet
            return;
        }

        if (targetType == SlotTargetType.FACILITY) {
            // No specific cache for facility availability yet
            return;
        }
    }

    private void recordHistory(Long slotId, SlotStatus from, SlotStatus to, String appointmentId, String reason) {
        historyRepository.save(SlotHistory.builder()
                .slotId(slotId)
                .statusFrom(from)
                .statusTo(to)
                .appointmentId(appointmentId)
                .reason(reason)
                .changedAt(LocalDateTime.now())
                .build());
    }

    private AvailableSlotsResponse buildAvailableResponse(List<SlotResponse> slots, int total, boolean hasMore) {
        return AvailableSlotsResponse.builder()
                .slots(slots)
                .totalAvailable(total)
                .hasMore(hasMore)
                .build();
    }
}
