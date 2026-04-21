package com.medbook.appointment.client.slot;

import com.medbook.appointment.client.model.EquipmentInfo;
import com.medbook.appointment.client.model.RoomInfo;
import com.medbook.appointment.client.model.SlotInfo;
import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.exception.EquipmentNotFoundException;
import com.medbook.appointment.exception.GrpcCommunicationException;
import com.medbook.appointment.exception.GrpcPermissionDeniedException;
import com.medbook.appointment.exception.RoomNotFoundException;
import com.medbook.appointment.exception.SlotNotFoundException;
import feign.FeignException;
import org.springframework.stereotype.Component;

@Component
public class SlotServiceClient {

    private final SlotServiceFeignClient slotServiceFeignClient;

    public SlotServiceClient(SlotServiceFeignClient slotServiceFeignClient) {
        this.slotServiceFeignClient = slotServiceFeignClient;
    }

    public SlotInfo getSlotById(String slotId) {
        try {
            SlotDetailsResponse response = requireResult(
                    slotServiceFeignClient.getSlot(slotId),
                    "Slot-service returned an empty response for slot: " + slotId);
            return new SlotInfo(
                    String.valueOf(response.id()),
                    response.targetType(),
                    response.targetId(),
                    response.startTime().toLocalDate().toString(),
                    response.startTime().toLocalTime().toString(),
                    response.endTime().toLocalTime().toString(),
                    "AVAILABLE".equalsIgnoreCase(response.status()));
        } catch (FeignException.NotFound ex) {
            throw new SlotNotFoundException("Slot not found: " + slotId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "slot-service");
        }
    }

    public RoomInfo getRoomById(String roomId) {
        try {
            RoomDetailsResponse response = requireResult(
                    slotServiceFeignClient.getRoom(roomId),
                    "Slot-service returned an empty response for room: " + roomId);
            return new RoomInfo(
                    response.id(),
                    response.roomName(),
                    response.roomCategory(),
                    "ACTIVE".equalsIgnoreCase(response.status()));
        } catch (FeignException.NotFound ex) {
            throw new RoomNotFoundException("Room not found: " + roomId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "slot-service");
        }
    }

    public EquipmentInfo getEquipmentById(String equipmentId) {
        try {
            EquipmentDetailsResponse response = requireResult(
                    slotServiceFeignClient.getEquipment(equipmentId),
                    "Slot-service returned an empty response for equipment: " + equipmentId);
            return new EquipmentInfo(
                    response.id(),
                    response.equipmentName(),
                    response.equipmentType(),
                    "ACTIVE".equalsIgnoreCase(response.status()));
        } catch (FeignException.NotFound ex) {
            throw new EquipmentNotFoundException("Equipment not found: " + equipmentId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "slot-service");
        }
    }

    public void reserveSlot(Long slotId, String appointmentId) {
        try {
            requireResult(
                    slotServiceFeignClient.reserveSlot(slotId, new AppointmentReferenceRequest(appointmentId)),
                    "Slot-service failed to reserve slot: " + slotId);
        } catch (FeignException.NotFound ex) {
            throw new SlotNotFoundException("Slot not found: " + slotId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "slot-service");
        }
    }

    public void releaseSlot(Long slotId, String appointmentId) {
        try {
            requireResult(
                    slotServiceFeignClient.releaseSlot(slotId, new AppointmentReferenceRequest(appointmentId)),
                    "Slot-service failed to release slot: " + slotId);
        } catch (FeignException.NotFound ex) {
            throw new SlotNotFoundException("Slot not found: " + slotId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "slot-service");
        }
    }

    private <T> T requireResult(ApiResponse<T> response, String message) {
        if (response == null || response.getResult() == null) {
            throw new GrpcCommunicationException(message);
        }
        return response.getResult();
    }

    private RuntimeException mapFeignException(FeignException ex, String serviceName) {
        return switch (ex.status()) {
            case 403 -> new GrpcPermissionDeniedException("Permission denied when calling " + serviceName, ex);
            case 400, 503 -> new GrpcCommunicationException(serviceName + " unavailable", ex);
            default -> new GrpcCommunicationException("Error calling " + serviceName, ex);
        };
    }
}
