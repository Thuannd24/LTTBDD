package com.medbook.appointment.client.slot;

import com.medbook.appointment.configuration.AuthenticationRequestInterceptor;
import com.medbook.appointment.dto.ApiResponse;
import java.time.LocalDateTime;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(
        name = "slot-service",
        path = "/slot",
        configuration = AuthenticationRequestInterceptor.class)
public interface SlotServiceFeignClient {

    @GetMapping("/slots/{slotId}")
    ApiResponse<SlotDetailsResponse> getSlot(@PathVariable("slotId") String slotId);

    @GetMapping("/rooms/{roomId}")
    ApiResponse<RoomDetailsResponse> getRoom(@PathVariable("roomId") String roomId);

    @GetMapping("/equipments/{equipmentId}")
    ApiResponse<EquipmentDetailsResponse> getEquipment(@PathVariable("equipmentId") String equipmentId);

    @PostMapping("/slots/{slotId}/reserve")
    ApiResponse<SlotDetailsResponse> reserveSlot(
            @PathVariable("slotId") Long slotId,
            @RequestBody AppointmentReferenceRequest request);

    @PostMapping("/slots/{slotId}/release")
    ApiResponse<SlotDetailsResponse> releaseSlot(
            @PathVariable("slotId") Long slotId,
            @RequestBody AppointmentReferenceRequest request);
}

record SlotDetailsResponse(
        Long id,
        String targetType,
        String targetId,
        LocalDateTime startTime,
        LocalDateTime endTime,
        String status
) {
}

record RoomDetailsResponse(
        String id,
        String roomName,
        String roomCategory,
        String status
) {
}

record EquipmentDetailsResponse(
        String id,
        String equipmentName,
        String equipmentType,
        String status
) {
}

record AppointmentReferenceRequest(String appointmentId) {
}
