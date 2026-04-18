package com.medbook.appointment.grpc.client;

import com.medbook.appointment.configuration.GrpcClientConfiguration;
import com.medbook.appointment.configuration.GrpcProperties;
import com.medbook.appointment.exception.EquipmentNotFoundException;
import com.medbook.appointment.exception.GrpcCommunicationException;
import com.medbook.appointment.exception.GrpcPermissionDeniedException;
import com.medbook.appointment.exception.RoomNotFoundException;
import com.medbook.appointment.exception.SlotNotFoundException;
import com.medbook.appointment.grpc.interceptor.AuthenticationInterceptor;
import com.medbook.appointment.grpc.interceptor.ErrorHandlingInterceptor;
import com.medbook.appointment.grpc.model.EquipmentInfo;
import com.medbook.appointment.grpc.model.RoomInfo;
import com.medbook.appointment.grpc.model.SlotInfo;
import com.medbook.grpc.slot.EquipmentResponse;
import com.medbook.grpc.slot.GetEquipmentByIdRequest;
import com.medbook.grpc.slot.GetRoomByIdRequest;
import com.medbook.grpc.slot.GetSlotByIdRequest;
import com.medbook.grpc.slot.RoomResponse;
import com.medbook.grpc.slot.SlotResponse;
import com.medbook.grpc.slot.SlotServiceGrpc;
import io.grpc.ClientInterceptors;
import io.grpc.ManagedChannel;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SlotGrpcClient {

    GrpcClientConfiguration grpcClientConfiguration;
    AuthenticationInterceptor authenticationInterceptor;
    ErrorHandlingInterceptor errorHandlingInterceptor;
    GrpcProperties grpcProperties;

    public SlotInfo getSlotById(String slotId) {
        ManagedChannel channel = grpcClientConfiguration.createManagedChannel(
                grpcProperties.getSlotServiceId(), grpcProperties.getSlotDefaultGrpcPort());
        try {
            SlotServiceGrpc.SlotServiceBlockingStub stub = SlotServiceGrpc.newBlockingStub(
                    ClientInterceptors.intercept(channel, authenticationInterceptor, errorHandlingInterceptor));

            SlotResponse response = stub
                    .withDeadlineAfter(grpcProperties.getCallTimeoutSeconds(), TimeUnit.SECONDS)
                    .getSlotById(GetSlotByIdRequest.newBuilder().setSlotId(slotId).build());

            if (response.getId().isBlank()) {
                throw new SlotNotFoundException("Slot not found: " + slotId);
            }

            return new SlotInfo(
                    response.getId(),
                    response.getTargetType(),
                    response.getTargetId(),
                    response.getDate(),
                    response.getStartTime(),
                    response.getEndTime(),
                    response.getAvailable());
        } catch (StatusRuntimeException ex) {
            throw mapSlotException(ex, slotId);
        } finally {
            channel.shutdownNow();
        }
    }

    public RoomInfo getRoomById(String roomId) {
        ManagedChannel channel = grpcClientConfiguration.createManagedChannel(
                grpcProperties.getSlotServiceId(), grpcProperties.getSlotDefaultGrpcPort());
        try {
            SlotServiceGrpc.SlotServiceBlockingStub stub = SlotServiceGrpc.newBlockingStub(
                    ClientInterceptors.intercept(channel, authenticationInterceptor, errorHandlingInterceptor));

            RoomResponse response = stub
                    .withDeadlineAfter(grpcProperties.getCallTimeoutSeconds(), TimeUnit.SECONDS)
                    .getRoomById(GetRoomByIdRequest.newBuilder().setRoomId(roomId).build());

            if (response.getId().isBlank()) {
                throw new RoomNotFoundException("Room not found: " + roomId);
            }

            return new RoomInfo(
                    response.getId(),
                    response.getName(),
                    response.getCategory(),
                    response.getActive());
        } catch (StatusRuntimeException ex) {
            throw mapRoomException(ex, roomId);
        } finally {
            channel.shutdownNow();
        }
    }

    public EquipmentInfo getEquipmentById(String equipmentId) {
        ManagedChannel channel = grpcClientConfiguration.createManagedChannel(
                grpcProperties.getSlotServiceId(), grpcProperties.getSlotDefaultGrpcPort());
        try {
            SlotServiceGrpc.SlotServiceBlockingStub stub = SlotServiceGrpc.newBlockingStub(
                    ClientInterceptors.intercept(channel, authenticationInterceptor, errorHandlingInterceptor));

            EquipmentResponse response = stub
                    .withDeadlineAfter(grpcProperties.getCallTimeoutSeconds(), TimeUnit.SECONDS)
                    .getEquipmentById(GetEquipmentByIdRequest.newBuilder().setEquipmentId(equipmentId).build());

            if (response.getId().isBlank()) {
                throw new EquipmentNotFoundException("Equipment not found: " + equipmentId);
            }

            return new EquipmentInfo(
                    response.getId(),
                    response.getName(),
                    response.getType(),
                    response.getActive());
        } catch (StatusRuntimeException ex) {
            throw mapEquipmentException(ex, equipmentId);
        } finally {
            channel.shutdownNow();
        }
    }

    private RuntimeException mapSlotException(StatusRuntimeException ex, String slotId) {
        Status.Code code = ex.getStatus().getCode();
        if (code == Status.Code.NOT_FOUND) return new SlotNotFoundException("Slot not found: " + slotId);
        if (code == Status.Code.PERMISSION_DENIED) return new GrpcPermissionDeniedException("Permission denied when calling slot-service", ex);
        if (code == Status.Code.DEADLINE_EXCEEDED || code == Status.Code.UNAVAILABLE) return new GrpcCommunicationException("Slot-service unavailable", ex);
        return new GrpcCommunicationException("Error calling slot-service", ex);
    }

    private RuntimeException mapRoomException(StatusRuntimeException ex, String roomId) {
        Status.Code code = ex.getStatus().getCode();
        if (code == Status.Code.NOT_FOUND) return new RoomNotFoundException("Room not found: " + roomId);
        if (code == Status.Code.PERMISSION_DENIED) return new GrpcPermissionDeniedException("Permission denied when calling slot-service", ex);
        if (code == Status.Code.DEADLINE_EXCEEDED || code == Status.Code.UNAVAILABLE) return new GrpcCommunicationException("Slot-service unavailable", ex);
        return new GrpcCommunicationException("Error calling slot-service", ex);
    }

    private RuntimeException mapEquipmentException(StatusRuntimeException ex, String equipmentId) {
        Status.Code code = ex.getStatus().getCode();
        if (code == Status.Code.NOT_FOUND) return new EquipmentNotFoundException("Equipment not found: " + equipmentId);
        if (code == Status.Code.PERMISSION_DENIED) return new GrpcPermissionDeniedException("Permission denied when calling slot-service", ex);
        if (code == Status.Code.DEADLINE_EXCEEDED || code == Status.Code.UNAVAILABLE) return new GrpcCommunicationException("Slot-service unavailable", ex);
        return new GrpcCommunicationException("Error calling slot-service", ex);
    }
}
