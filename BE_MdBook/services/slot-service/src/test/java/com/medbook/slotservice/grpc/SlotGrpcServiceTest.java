package com.medbook.slotservice.grpc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.medbook.grpc.slot.GetEquipmentByIdRequest;
import com.medbook.grpc.slot.GetRoomByIdRequest;
import com.medbook.grpc.slot.GetSlotByIdRequest;
import com.medbook.grpc.slot.ReleaseSlotRequest;
import com.medbook.grpc.slot.ReserveSlotRequest;
import com.medbook.slotservice.dto.response.EquipmentResponse;
import com.medbook.slotservice.dto.response.RoomResponse;
import com.medbook.slotservice.dto.response.SlotResponse;
import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.EquipmentType;
import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.service.EquipmentService;
import com.medbook.slotservice.service.RoomService;
import com.medbook.slotservice.service.SlotService;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.StreamObserver;
import java.time.LocalDateTime;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class SlotGrpcServiceTest {

    @Mock
    private SlotService slotService;

    @Mock
    private RoomService roomService;

    @Mock
    private EquipmentService equipmentService;

    private SlotGrpcService slotGrpcService;

    @BeforeEach
    void setUp() {
        slotGrpcService = new SlotGrpcService(slotService, roomService, equipmentService);
    }

    @Test
    void getSlotById_mapsAvailableFlag() {
        when(slotService.getSlot(10L)).thenReturn(slotResponse(SlotStatus.AVAILABLE));

        TestObserver<com.medbook.grpc.slot.SlotResponse> observer = new TestObserver<>();
        slotGrpcService.getSlotById(GetSlotByIdRequest.newBuilder().setSlotId("10").build(), observer);

        assertThat(observer.response.getId()).isEqualTo("10");
        assertThat(observer.response.getAvailable()).isTrue();
    }

    @Test
    void getRoomById_mapsRoom() {
        when(roomService.getRoom("room-1")).thenReturn(RoomResponse.builder()
                .id("room-1")
                .roomName("Room A")
                .roomCategory(RoomCategory.ULTRASOUND_ROOM)
                .status(RoomStatus.ACTIVE)
                .build());

        TestObserver<com.medbook.grpc.slot.RoomResponse> observer = new TestObserver<>();
        slotGrpcService.getRoomById(GetRoomByIdRequest.newBuilder().setRoomId("room-1").build(), observer);

        assertThat(observer.response.getCategory()).isEqualTo("ULTRASOUND_ROOM");
        assertThat(observer.response.getActive()).isTrue();
    }

    @Test
    void getEquipmentById_mapsEquipment() {
        when(equipmentService.getEquipment("equipment-1")).thenReturn(EquipmentResponse.builder()
                .id("equipment-1")
                .equipmentName("Equipment A")
                .equipmentType(EquipmentType.ULTRASOUND_MACHINE)
                .status(EquipmentStatus.ACTIVE)
                .build());

        TestObserver<com.medbook.grpc.slot.EquipmentResponse> observer = new TestObserver<>();
        slotGrpcService.getEquipmentById(GetEquipmentByIdRequest.newBuilder().setEquipmentId("equipment-1").build(), observer);

        assertThat(observer.response.getType()).isEqualTo("ULTRASOUND_MACHINE");
        assertThat(observer.response.getActive()).isTrue();
    }

    @Test
    void reserveSlot_returnsReservedResponse() {
        when(slotService.reserveSlot(org.mockito.ArgumentMatchers.eq(10L), org.mockito.ArgumentMatchers.any()))
                .thenReturn(slotResponse(SlotStatus.RESERVED));

        TestObserver<com.medbook.grpc.slot.SlotResponse> observer = new TestObserver<>();
        slotGrpcService.reserveSlot(ReserveSlotRequest.newBuilder()
                .setSlotId("10")
                .setAppointmentId("apt-1")
                .build(), observer);

        assertThat(observer.response.getAvailable()).isFalse();
    }

    @Test
    void releaseSlot_mapsAppException() {
        when(slotService.releaseSlot(10L, "apt-1"))
                .thenThrow(new AppException(ErrorCode.SLOT_APPOINTMENT_MISMATCH));

        TestObserver<com.medbook.grpc.slot.SlotResponse> observer = new TestObserver<>();
        slotGrpcService.releaseSlot(ReleaseSlotRequest.newBuilder()
                .setSlotId("10")
                .setAppointmentId("apt-1")
                .build(), observer);

        assertThat(statusCode(observer.error)).isEqualTo(Status.Code.INVALID_ARGUMENT);
    }

    private SlotResponse slotResponse(SlotStatus status) {
        return SlotResponse.builder()
                .id(10L)
                .targetType(SlotTargetType.ROOM)
                .targetId("room-1")
                .facilityId(1L)
                .startTime(LocalDateTime.of(2026, 4, 10, 9, 0))
                .endTime(LocalDateTime.of(2026, 4, 10, 9, 30))
                .status(status)
                .build();
    }

    private Status.Code statusCode(Throwable throwable) {
        return ((StatusRuntimeException) throwable).getStatus().getCode();
    }

    private static class TestObserver<T> implements StreamObserver<T> {
        private T response;
        private Throwable error;

        @Override
        public void onNext(T value) {
            this.response = value;
        }

        @Override
        public void onError(Throwable t) {
            this.error = t;
        }

        @Override
        public void onCompleted() {
        }
    }
}
