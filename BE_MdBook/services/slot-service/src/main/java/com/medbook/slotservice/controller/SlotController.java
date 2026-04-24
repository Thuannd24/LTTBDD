package com.medbook.slotservice.controller;

import com.medbook.slotservice.dto.ApiResponse;
import com.medbook.slotservice.dto.request.BlockSlotRequest;
import com.medbook.slotservice.dto.request.BookSlotRequest;
import com.medbook.slotservice.dto.request.CreateRecurringSlotRequest;

import com.medbook.slotservice.dto.request.ReleaseSlotRequest;
import com.medbook.slotservice.dto.response.AvailableSlotsResponse;
import com.medbook.slotservice.dto.response.CreateRecurringResult;
import com.medbook.slotservice.dto.response.RecurringSlotConfigResponse;
import com.medbook.slotservice.dto.response.SlotResponse;
import com.medbook.slotservice.entity.SlotHistory;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import com.medbook.slotservice.service.SlotService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping
@RequiredArgsConstructor
public class SlotController {

    private final SlotService slotService;

    @GetMapping("/slots/health")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }

    @GetMapping("/slots/facility/available")
    public ApiResponse<AvailableSlotsResponse> getAvailableFacilitySlots(@Valid com.medbook.slotservice.dto.request.FacilityAvailabilityQuery query) {
        return ApiResponse.<AvailableSlotsResponse>builder()
                .result(slotService.findAvailableFacilitySlots(query))
                .build();
    }

    @GetMapping("/slots/{slotId}")
    public ApiResponse<SlotResponse> getSlot(@PathVariable Long slotId) {
        return ApiResponse.<SlotResponse>builder()
                .result(slotService.getSlot(slotId))
                .build();
    }

    @PostMapping("/schedule-configs")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CreateRecurringResult> createRecurring(@Valid @RequestBody CreateRecurringSlotRequest request) {
        return ApiResponse.<CreateRecurringResult>builder()
                .message("Schedule config created successfully")
                .result(slotService.createRecurringSlots(request))
                .build();
    }

    @GetMapping("/schedule-configs")
    public ApiResponse<List<RecurringSlotConfigResponse>> getScheduleConfigs(
            @RequestParam(required = false) SlotTargetType targetType,
            @RequestParam(required = false) String targetId,
            @RequestParam Long facilityId) {
        return ApiResponse.<List<RecurringSlotConfigResponse>>builder()
                .result(slotService.getScheduleConfigs(targetType, targetId, facilityId))
                .build();
    }

    @PostMapping("/slots/{slotId}/reserve")
    public ApiResponse<SlotResponse> reserveSlot(
            @PathVariable Long slotId,
            @Valid @RequestBody BookSlotRequest request) {
        return ApiResponse.<SlotResponse>builder().result(slotService.reserveSlot(slotId, request)).build();
    }

    @PostMapping("/slots/{slotId}/release")
    public ApiResponse<SlotResponse> releaseSlot(
            @PathVariable Long slotId,
            @RequestBody(required = false) ReleaseSlotRequest request) {
        return ApiResponse.<SlotResponse>builder()
                .result(slotService.releaseSlot(slotId, request != null ? request.getAppointmentId() : null))
                .build();
    }

    @PostMapping("/slots/{slotId}/block")
    public ApiResponse<SlotResponse> blockSlot(
            @PathVariable Long slotId,
            @Valid @RequestBody BlockSlotRequest request) {
        return ApiResponse.<SlotResponse>builder().result(slotService.blockSlot(slotId, request)).build();
    }

    @GetMapping("/slots/{slotId}/history")
    public ApiResponse<List<SlotHistory>> getSlotHistory(@PathVariable Long slotId) {
        return ApiResponse.<List<SlotHistory>>builder().result(slotService.getSlotHistory(slotId)).build();
    }
}
