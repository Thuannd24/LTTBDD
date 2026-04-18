package com.medbook.slotservice.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.medbook.slotservice.dto.request.BlockSlotRequest;
import com.medbook.slotservice.dto.request.BookSlotRequest;
import com.medbook.slotservice.dto.request.CreateRecurringSlotRequest;
import com.medbook.slotservice.dto.request.EquipmentAvailabilityQuery;
import com.medbook.slotservice.dto.request.RoomAvailabilityQuery;
import com.medbook.slotservice.dto.response.AvailableSlotsResponse;
import com.medbook.slotservice.dto.response.CreateRecurringResult;
import com.medbook.slotservice.dto.response.SlotResponse;
import com.medbook.slotservice.entity.Equipment;
import com.medbook.slotservice.entity.RecurringSlotConfig;
import com.medbook.slotservice.entity.Room;
import com.medbook.slotservice.entity.Slot;
import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.EquipmentType;
import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.mapper.RecurringSlotConfigMapper;
import com.medbook.slotservice.mapper.SlotMapper;
import com.medbook.slotservice.repository.EquipmentRepository;
import com.medbook.slotservice.repository.RecurringSlotConfigRepository;
import com.medbook.slotservice.repository.RoomRepository;
import com.medbook.slotservice.repository.SlotHistoryRepository;
import com.medbook.slotservice.repository.SlotRepository;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;

@ExtendWith(MockitoExtension.class)
@DisplayName("SlotService Unit Tests")
class SlotServiceTest {

    @Mock
    SlotRepository slotRepository;

    @Mock
    RecurringSlotConfigRepository recurringRepository;

    @Mock
    SlotHistoryRepository historyRepository;

    @Mock
    RoomRepository roomRepository;

    @Mock
    EquipmentRepository equipmentRepository;

    @Mock
    SlotMapper slotMapper;

    @Mock
    RecurringSlotConfigMapper recurringMapper;

    SlotService slotService;
    TestSlotCacheService cacheService;
    TestSlotGeneratorService generatorService;

    @BeforeEach
    void setUp() {
        cacheService = new TestSlotCacheService();
        generatorService = new TestSlotGeneratorService();
        slotService = new SlotService(
                slotRepository,
                recurringRepository,
                historyRepository,
                roomRepository,
                equipmentRepository,
                slotMapper,
                recurringMapper,
                cacheService,
                generatorService);
    }

    private Room buildRoom() {
        return Room.builder()
                .id("room-1")
                .facilityId(2L)
                .roomCode("R101")
                .roomName("Ultrasound Room 1")
                .roomCategory(RoomCategory.ULTRASOUND_ROOM)
                .status(RoomStatus.ACTIVE)
                .build();
    }

    private Equipment buildEquipment() {
        return Equipment.builder()
                .id("equipment-1")
                .facilityId(2L)
                .roomId("room-1")
                .equipmentCode("US-1")
                .equipmentName("Ultrasound Machine 1")
                .equipmentType(EquipmentType.ULTRASOUND_MACHINE)
                .status(EquipmentStatus.ACTIVE)
                .build();
    }

    private Slot buildSlot(Long id, SlotTargetType targetType, String targetId, SlotStatus status) {
        return Slot.builder()
                .id(id)
                .targetType(targetType)
                .targetId(targetId)
                .facilityId(2L)
                .startTime(LocalDateTime.of(2026, 4, 15, 9, 0))
                .endTime(LocalDateTime.of(2026, 4, 15, 9, 30))
                .status(status)
                .build();
    }

    private SlotResponse buildSlotResponse(Long id, SlotTargetType targetType, String targetId, SlotStatus status) {
        return SlotResponse.builder()
                .id(id)
                .targetType(targetType)
                .targetId(targetId)
                .facilityId(2L)
                .status(status)
                .build();
    }

    @Nested
    @DisplayName("createRecurringSlots")
    class CreateRecurringSlots {

        @Test
        @DisplayName("Success: creates room config and generates slots")
        void success() {
            CreateRecurringSlotRequest req = new CreateRecurringSlotRequest();
            req.setTargetType(SlotTargetType.ROOM);
            req.setTargetId("room-1");
            req.setFacilityId(2L);
            req.setDayOfWeek(DayOfWeek.MONDAY);
            req.setStartTime(LocalTime.of(9, 0));
            req.setEndTime(LocalTime.of(17, 0));
            req.setSlotDurationMinutes(30);

            when(roomRepository.findById("room-1")).thenReturn(Optional.of(buildRoom()));
            when(recurringRepository.existsByTargetTypeAndTargetIdAndFacilityIdAndDayOfWeekAndStartTimeAndEndTime(
                            any(), any(), anyLong(), any(), any(), any()))
                    .thenReturn(false);
            when(recurringRepository.save(any())).thenReturn(RecurringSlotConfig.builder()
                    .id(1L)
                    .targetType(SlotTargetType.ROOM)
                    .targetId("room-1")
                    .facilityId(2L)
                    .build());
            generatorService.generatedCount = 240;

            CreateRecurringResult result = slotService.createRecurringSlots(req);

            assertThat(result.getConfigId()).isEqualTo(1L);
            assertThat(result.getSlotsCreated()).isEqualTo(240);
            assertThat(cacheService.lastInvalidatedRoomFacilityId).isEqualTo(2L);
            assertThat(cacheService.lastInvalidatedRoomCategory).isEqualTo(RoomCategory.ULTRASOUND_ROOM);
        }

        @Test
        @DisplayName("Throws RECURRING_CONFIG_ALREADY_EXISTS when duplicate config")
        void duplicateConfig() {
            CreateRecurringSlotRequest req = new CreateRecurringSlotRequest();
            req.setTargetType(SlotTargetType.ROOM);
            req.setTargetId("room-1");
            req.setFacilityId(2L);
            req.setDayOfWeek(DayOfWeek.MONDAY);
            req.setStartTime(LocalTime.of(9, 0));
            req.setEndTime(LocalTime.of(17, 0));
            req.setSlotDurationMinutes(30);

            when(roomRepository.findById("room-1")).thenReturn(Optional.of(buildRoom()));
            when(recurringRepository.existsByTargetTypeAndTargetIdAndFacilityIdAndDayOfWeekAndStartTimeAndEndTime(
                            any(), any(), anyLong(), any(), any(), any()))
                    .thenReturn(true);

            assertThatThrownBy(() -> slotService.createRecurringSlots(req))
                    .isInstanceOf(AppException.class)
                    .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.RECURRING_CONFIG_ALREADY_EXISTS));
        }
    }

    @Nested
    @DisplayName("findAvailableRoomSlots")
    class FindAvailableRoomSlots {

        @Test
        @DisplayName("Returns cached result if cache hit")
        void cacheHit() {
            RoomAvailabilityQuery query = new RoomAvailabilityQuery();
            query.setFacilityId(2L);
            query.setRoomCategory(RoomCategory.ULTRASOUND_ROOM);
            query.setDate(LocalDate.of(2026, 4, 15));
            query.setLimit(5);

            AvailableSlotsResponse cached = AvailableSlotsResponse.builder()
                    .slots(List.of(buildSlotResponse(101L, SlotTargetType.ROOM, "room-1", SlotStatus.AVAILABLE)))
                    .totalAvailable(10)
                    .hasMore(true)
                    .build();
            cacheService.roomCacheKey = "slot:rooms:2:ULTRASOUND_ROOM:2026-04-15:5";
            cacheService.cachedResponse = cached;

            AvailableSlotsResponse result = slotService.findAvailableRoomSlots(query);

            assertThat(result.getSlots()).hasSize(1);
            assertThat(result.getTotalAvailable()).isEqualTo(10);
            assertThat(result.getHasMore()).isTrue();
            verifyNoInteractions(slotRepository);
        }

        @Test
        @DisplayName("Queries DB and caches result on cache miss")
        void cacheMiss() {
            RoomAvailabilityQuery query = new RoomAvailabilityQuery();
            query.setFacilityId(2L);
            query.setRoomCategory(RoomCategory.ULTRASOUND_ROOM);
            query.setDate(LocalDate.of(2026, 4, 15));
            query.setLimit(5);

            cacheService.roomCacheKey = "key";
            when(roomRepository.findByFacilityIdAndRoomCategoryAndStatus(2L, RoomCategory.ULTRASOUND_ROOM, RoomStatus.ACTIVE))
                    .thenReturn(List.of(buildRoom()));
            when(slotRepository.findByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThanOrderByStartTimeAsc(
                            any(), any(), any(), any(), any(), any()))
                    .thenReturn(new PageImpl<>(List.of(buildSlot(101L, SlotTargetType.ROOM, "room-1", SlotStatus.AVAILABLE))));
            when(slotRepository.countByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThan(
                            any(), any(), any(), any(), any()))
                    .thenReturn(10L);
            when(slotMapper.toResponse(any())).thenReturn(buildSlotResponse(101L, SlotTargetType.ROOM, "room-1", SlotStatus.AVAILABLE));

            AvailableSlotsResponse result = slotService.findAvailableRoomSlots(query);

            assertThat(result.getSlots()).hasSize(1);
            assertThat(result.getTotalAvailable()).isEqualTo(10);
            assertThat(result.getHasMore()).isTrue();
            assertThat(cacheService.lastCachedKey).isEqualTo("key");
            assertThat(cacheService.lastCachedResponse).isNotNull();
            assertThat(cacheService.lastCachedResponse.getTotalAvailable()).isEqualTo(10);
            assertThat(cacheService.lastCachedResponse.getHasMore()).isTrue();
        }
    }

    @Nested
    @DisplayName("findAvailableEquipmentSlots")
    class FindAvailableEquipmentSlots {

        @Test
        @DisplayName("Queries active equipments in room")
        void success() {
            EquipmentAvailabilityQuery query = new EquipmentAvailabilityQuery();
            query.setFacilityId(2L);
            query.setRoomId("room-1");
            query.setEquipmentType(EquipmentType.ULTRASOUND_MACHINE);
            query.setDate(LocalDate.of(2026, 4, 15));
            query.setLimit(5);

            cacheService.equipmentCacheKey = "equipment-key";
            when(roomRepository.findById("room-1")).thenReturn(Optional.of(buildRoom()));
            when(equipmentRepository.findByRoomIdAndEquipmentTypeAndStatus("room-1", EquipmentType.ULTRASOUND_MACHINE, EquipmentStatus.ACTIVE))
                    .thenReturn(List.of(buildEquipment()));
            when(slotRepository.findByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThanOrderByStartTimeAsc(
                            any(), any(), any(), any(), any(), any()))
                    .thenReturn(new PageImpl<>(List.of(buildSlot(
                            201L, SlotTargetType.EQUIPMENT, "equipment-1", SlotStatus.AVAILABLE))));
            when(slotRepository.countByTargetTypeAndTargetIdInAndStatusAndStartTimeGreaterThanEqualAndStartTimeLessThan(
                            any(), any(), any(), any(), any()))
                    .thenReturn(1L);
            when(slotMapper.toResponse(any()))
                    .thenReturn(buildSlotResponse(201L, SlotTargetType.EQUIPMENT, "equipment-1", SlotStatus.AVAILABLE));

            AvailableSlotsResponse result = slotService.findAvailableEquipmentSlots(query);

            assertThat(result.getSlots()).hasSize(1);
            assertThat(result.getTotalAvailable()).isEqualTo(1);
            assertThat(cacheService.lastCachedKey).isEqualTo("equipment-key");
            assertThat(cacheService.lastCachedResponse).isNotNull();
        }
    }

    @Nested
    @DisplayName("reserveSlot")
    class ReserveSlot {

        @Test
        @DisplayName("Success: reserves available room slot")
        void success() {
            Slot slot = buildSlot(102L, SlotTargetType.ROOM, "room-1", SlotStatus.AVAILABLE);
            when(slotRepository.findByIdWithLock(102L)).thenReturn(Optional.of(slot));
            when(slotRepository.atomicReserveSlot(102L, SlotStatus.RESERVED, "apt-42")).thenReturn(1);
            Slot reservedSlot = buildSlot(102L, SlotTargetType.ROOM, "room-1", SlotStatus.RESERVED);
            reservedSlot.setAppointmentId("apt-42");
            when(slotRepository.findById(102L)).thenReturn(Optional.of(reservedSlot));
            when(roomRepository.findById("room-1")).thenReturn(Optional.of(buildRoom()));
            when(slotMapper.toResponse(reservedSlot))
                    .thenReturn(buildSlotResponse(102L, SlotTargetType.ROOM, "room-1", SlotStatus.RESERVED));

            BookSlotRequest req = new BookSlotRequest();
            req.setAppointmentId("apt-42");
            SlotResponse result = slotService.reserveSlot(102L, req);

            assertThat(result.getStatus()).isEqualTo(SlotStatus.RESERVED);
            verify(historyRepository).save(any());
            assertThat(cacheService.lastInvalidatedRoomFacilityId).isEqualTo(2L);
            assertThat(cacheService.lastInvalidatedRoomCategory).isEqualTo(RoomCategory.ULTRASOUND_ROOM);
        }

        @Test
        @DisplayName("Throws SLOT_NOT_FOUND when slot does not exist")
        void slotNotFound() {
            when(slotRepository.findByIdWithLock(999L)).thenReturn(Optional.empty());
            BookSlotRequest req = new BookSlotRequest();
            req.setAppointmentId("apt-42");

            assertThatThrownBy(() -> slotService.reserveSlot(999L, req))
                    .isInstanceOf(AppException.class)
                    .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.SLOT_NOT_FOUND));
        }

        @Test
        @DisplayName("Throws SLOT_ALREADY_RESERVED when slot is not AVAILABLE")
        void slotAlreadyReserved() {
            Slot slot = buildSlot(102L, SlotTargetType.ROOM, "room-1", SlotStatus.RESERVED);
            when(slotRepository.findByIdWithLock(102L)).thenReturn(Optional.of(slot));
            BookSlotRequest req = new BookSlotRequest();
            req.setAppointmentId("apt-42");

            assertThatThrownBy(() -> slotService.reserveSlot(102L, req))
                    .isInstanceOf(AppException.class)
                    .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.SLOT_ALREADY_RESERVED));
        }
    }

    @Nested
    @DisplayName("releaseSlot")
    class ReleaseSlot {

        @Test
        @DisplayName("Success: releases reserved equipment slot")
        void success() {
            Slot slot = buildSlot(202L, SlotTargetType.EQUIPMENT, "equipment-1", SlotStatus.RESERVED);
            slot.setAppointmentId("apt-42");
            when(slotRepository.findByIdWithLock(202L)).thenReturn(Optional.of(slot));
            when(slotRepository.save(any())).thenReturn(slot);
            when(equipmentRepository.findById("equipment-1")).thenReturn(Optional.of(buildEquipment()));
            when(slotMapper.toResponse(any()))
                    .thenReturn(buildSlotResponse(202L, SlotTargetType.EQUIPMENT, "equipment-1", SlotStatus.AVAILABLE));

            SlotResponse result = slotService.releaseSlot(202L);

            assertThat(result).isNotNull();
            verify(historyRepository).save(any());
            assertThat(cacheService.lastInvalidatedEquipmentFacilityId).isEqualTo(2L);
            assertThat(cacheService.lastInvalidatedEquipmentRoomId).isEqualTo("room-1");
        }

        @Test
        @DisplayName("Throws SLOT_NOT_RESERVED when slot is AVAILABLE")
        void notReserved() {
            Slot slot = buildSlot(202L, SlotTargetType.EQUIPMENT, "equipment-1", SlotStatus.AVAILABLE);
            when(slotRepository.findByIdWithLock(202L)).thenReturn(Optional.of(slot));

            assertThatThrownBy(() -> slotService.releaseSlot(202L))
                    .isInstanceOf(AppException.class)
                    .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.SLOT_NOT_RESERVED));
        }

        @Test
        @DisplayName("Throws SLOT_APPOINTMENT_MISMATCH when appointment id does not match")
        void appointmentMismatch() {
            Slot slot = buildSlot(202L, SlotTargetType.EQUIPMENT, "equipment-1", SlotStatus.RESERVED);
            slot.setAppointmentId("apt-42");
            when(slotRepository.findByIdWithLock(202L)).thenReturn(Optional.of(slot));

            assertThatThrownBy(() -> slotService.releaseSlot(202L, "apt-other"))
                    .isInstanceOf(AppException.class)
                    .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.SLOT_APPOINTMENT_MISMATCH));
        }
    }

    @Nested
    @DisplayName("blockSlot")
    class BlockSlot {

        @Test
        @DisplayName("Success: blocks available slot")
        void success() {
            Slot slot = buildSlot(104L, SlotTargetType.ROOM, "room-1", SlotStatus.AVAILABLE);
            when(slotRepository.findById(104L)).thenReturn(Optional.of(slot));
            when(slotRepository.save(any())).thenReturn(slot);
            when(roomRepository.findById("room-1")).thenReturn(Optional.of(buildRoom()));
            when(slotMapper.toResponse(any()))
                    .thenReturn(buildSlotResponse(104L, SlotTargetType.ROOM, "room-1", SlotStatus.BLOCKED));

            BlockSlotRequest req = new BlockSlotRequest();
            req.setReason("Maintenance");
            SlotResponse result = slotService.blockSlot(104L, req);

            assertThat(result.getStatus()).isEqualTo(SlotStatus.BLOCKED);
            verify(historyRepository).save(any());
            assertThat(cacheService.lastInvalidatedRoomFacilityId).isEqualTo(2L);
            assertThat(cacheService.lastInvalidatedRoomCategory).isEqualTo(RoomCategory.ULTRASOUND_ROOM);
        }

        @Test
        @DisplayName("Throws SLOT_CANNOT_BLOCK when slot is RESERVED")
        void cannotBlockReserved() {
            Slot slot = buildSlot(104L, SlotTargetType.ROOM, "room-1", SlotStatus.RESERVED);
            when(slotRepository.findById(104L)).thenReturn(Optional.of(slot));

            BlockSlotRequest req = new BlockSlotRequest();
            req.setReason("Test");

            assertThatThrownBy(() -> slotService.blockSlot(104L, req))
                    .isInstanceOf(AppException.class)
                    .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.SLOT_CANNOT_BLOCK));
        }
    }

    static class TestSlotCacheService extends SlotCacheService {

        String roomCacheKey;
        String equipmentCacheKey;
        AvailableSlotsResponse cachedResponse;
        String lastCachedKey;
        AvailableSlotsResponse lastCachedResponse;
        Long lastInvalidatedRoomFacilityId;
        RoomCategory lastInvalidatedRoomCategory;
        Long lastInvalidatedEquipmentFacilityId;
        String lastInvalidatedEquipmentRoomId;

        TestSlotCacheService() {
            super(null);
        }

        @Override
        public String buildRoomCacheKey(RoomAvailabilityQuery query) {
            return roomCacheKey != null ? roomCacheKey : super.buildRoomCacheKey(query);
        }

        @Override
        public String buildEquipmentCacheKey(EquipmentAvailabilityQuery query) {
            return equipmentCacheKey != null ? equipmentCacheKey : super.buildEquipmentCacheKey(query);
        }

        @Override
        public AvailableSlotsResponse getAvailableSlots(String key) {
            return cachedResponse;
        }

        @Override
        public void setAvailableSlots(String key, AvailableSlotsResponse response) {
            lastCachedKey = key;
            lastCachedResponse = response;
            cachedResponse = response;
        }

        @Override
        public void invalidateRoomAvailability(Long facilityId, RoomCategory roomCategory) {
            lastInvalidatedRoomFacilityId = facilityId;
            lastInvalidatedRoomCategory = roomCategory;
        }

        @Override
        public void invalidateEquipmentAvailability(Long facilityId, String roomId) {
            lastInvalidatedEquipmentFacilityId = facilityId;
            lastInvalidatedEquipmentRoomId = roomId;
        }
    }

    static class TestSlotGeneratorService extends SlotGeneratorService {

        int generatedCount;

        TestSlotGeneratorService() {
            super(null);
        }

        @Override
        public int generateSlotsForNextDays(RecurringSlotConfig config, int days) {
            return generatedCount;
        }
    }
}
