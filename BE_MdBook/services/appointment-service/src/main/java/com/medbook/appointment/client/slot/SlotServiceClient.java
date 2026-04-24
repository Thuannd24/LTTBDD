package com.medbook.appointment.client.slot;

import com.medbook.appointment.client.model.SlotInfo;
import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.exception.ServiceCommunicationException;
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
                    "Slot not found: " + slotId);
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
            throw new ServiceCommunicationException("Error calling slot-service", ex);
        }
    }

    public void reserveSlot(Long slotId, String appointmentId) {
        try {
            requireResult(
                    slotServiceFeignClient.reserveSlot(slotId, new AppointmentReferenceRequest(appointmentId)),
                    "Failed to reserve slot: " + slotId);
        } catch (FeignException.NotFound ex) {
            throw new SlotNotFoundException("Slot not found: " + slotId);
        } catch (FeignException ex) {
            throw new ServiceCommunicationException("Error reserving slot", ex);
        }
    }

    public void releaseSlot(Long slotId, String appointmentId) {
        try {
            requireResult(
                    slotServiceFeignClient.releaseSlot(slotId, new AppointmentReferenceRequest(appointmentId)),
                    "Failed to release slot: " + slotId);
        } catch (FeignException.NotFound ex) {
            throw new SlotNotFoundException("Slot not found: " + slotId);
        } catch (FeignException ex) {
            throw new ServiceCommunicationException("Error releasing slot", ex);
        }
    }

    private <T> T requireResult(ApiResponse<T> response, String message) {
        if (response == null || response.getResult() == null) {
            throw new ServiceCommunicationException(message);
        }
        return response.getResult();
    }
}
