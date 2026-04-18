package com.medbook.slotservice.grpc;

import com.medbook.slotservice.dto.request.BookSlotRequest;
import com.medbook.slotservice.dto.response.EquipmentResponse;
import com.medbook.slotservice.dto.response.RoomResponse;
import com.medbook.slotservice.dto.response.SlotResponse;
import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.RoomStatus;
import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.service.EquipmentService;
import com.medbook.slotservice.service.RoomService;
import com.medbook.slotservice.service.SlotService;
import com.medbook.grpc.slot.GetEquipmentByIdRequest;
import com.medbook.grpc.slot.GetRoomByIdRequest;
import com.medbook.grpc.slot.GetSlotByIdRequest;
import com.medbook.grpc.slot.ReleaseSlotRequest;
import com.medbook.grpc.slot.ReserveSlotRequest;
import com.medbook.grpc.slot.SlotServiceGrpc;
import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;
import net.devh.boot.grpc.server.service.GrpcService;

@GrpcService
@RequiredArgsConstructor
public class SlotGrpcService extends SlotServiceGrpc.SlotServiceImplBase {

    private final SlotService slotService;
    private final RoomService roomService;
    private final EquipmentService equipmentService;

    @Override
    public void getSlotById(GetSlotByIdRequest request,
            StreamObserver<com.medbook.grpc.slot.SlotResponse> responseObserver) {
        try {
            SlotResponse response = slotService.getSlot(parseSlotId(request.getSlotId()));
            responseObserver.onNext(toGrpcSlotResponse(response));
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void getRoomById(GetRoomByIdRequest request,
            StreamObserver<com.medbook.grpc.slot.RoomResponse> responseObserver) {
        try {
            RoomResponse response = roomService.getRoom(request.getRoomId());
            responseObserver.onNext(com.medbook.grpc.slot.RoomResponse.newBuilder()
                    .setId(response.getId())
                    .setName(response.getRoomName())
                    .setCategory(response.getRoomCategory().name())
                    .setActive(response.getStatus() == RoomStatus.ACTIVE)
                    .build());
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void getEquipmentById(GetEquipmentByIdRequest request,
            StreamObserver<com.medbook.grpc.slot.EquipmentResponse> responseObserver) {
        try {
            EquipmentResponse response = equipmentService.getEquipment(request.getEquipmentId());
            responseObserver.onNext(com.medbook.grpc.slot.EquipmentResponse.newBuilder()
                    .setId(response.getId())
                    .setName(response.getEquipmentName())
                    .setType(response.getEquipmentType().name())
                    .setActive(response.getStatus() == EquipmentStatus.ACTIVE)
                    .build());
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void reserveSlot(ReserveSlotRequest request,
            StreamObserver<com.medbook.grpc.slot.SlotResponse> responseObserver) {
        try {
            SlotResponse response = slotService.reserveSlot(parseSlotId(request.getSlotId()),
                    buildBookSlotRequest(request.getAppointmentId()));
            responseObserver.onNext(toGrpcSlotResponse(response));
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void releaseSlot(ReleaseSlotRequest request,
            StreamObserver<com.medbook.grpc.slot.SlotResponse> responseObserver) {
        try {
            SlotResponse response = slotService.releaseSlot(parseSlotId(request.getSlotId()),
                    request.getAppointmentId());
            responseObserver.onNext(toGrpcSlotResponse(response));
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    private Long parseSlotId(String slotId) {
        try {
            return Long.parseLong(slotId);
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Invalid slot id");
        }
    }

    private BookSlotRequest buildBookSlotRequest(String appointmentId) {
        BookSlotRequest request = new BookSlotRequest();
        request.setAppointmentId(appointmentId);
        return request;
    }

    private com.medbook.grpc.slot.SlotResponse toGrpcSlotResponse(SlotResponse response) {
        return com.medbook.grpc.slot.SlotResponse.newBuilder()
                .setId(String.valueOf(response.getId()))
                .setTargetType(response.getTargetType().name())
                .setTargetId(response.getTargetId())
                .setDate(response.getStartTime().toLocalDate().toString())
                .setStartTime(response.getStartTime().toLocalTime().toString())
                .setEndTime(response.getEndTime().toLocalTime().toString())
                .setAvailable(response.getStatus() == SlotStatus.AVAILABLE)
                .build();
    }
}
