package com.medbook.slotservice.controller;

import com.medbook.slotservice.dto.ApiResponse;
import com.medbook.slotservice.dto.request.CreateEquipmentRequest;
import com.medbook.slotservice.dto.request.UpdateEquipmentRequest;
import com.medbook.slotservice.dto.response.EquipmentResponse;
import com.medbook.slotservice.service.EquipmentService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class EquipmentController {

    private final EquipmentService equipmentService;

    @PostMapping("/equipments")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<EquipmentResponse> createEquipment(@Valid @RequestBody CreateEquipmentRequest request) {
        return ApiResponse.<EquipmentResponse>builder().result(equipmentService.createEquipment(request)).build();
    }

    @GetMapping("/equipments/{equipmentId}")
    public ApiResponse<EquipmentResponse> getEquipment(@PathVariable String equipmentId) {
        return ApiResponse.<EquipmentResponse>builder().result(equipmentService.getEquipment(equipmentId)).build();
    }

    @GetMapping("/equipments")
    public ApiResponse<List<EquipmentResponse>> listEquipments(
            @RequestParam(required = false) Long facilityId,
            @RequestParam(required = false) String roomId) {
        return ApiResponse.<List<EquipmentResponse>>builder()
                .result(equipmentService.listEquipments(facilityId, roomId))
                .build();
    }

    @GetMapping("/rooms/{roomId}/equipments")
    public ApiResponse<List<EquipmentResponse>> listByRoom(@PathVariable String roomId) {
        return ApiResponse.<List<EquipmentResponse>>builder()
                .result(equipmentService.listEquipmentsByRoom(roomId))
                .build();
    }

    @PutMapping("/equipments/{equipmentId}")
    public ApiResponse<EquipmentResponse> updateEquipment(
            @PathVariable String equipmentId,
            @Valid @RequestBody UpdateEquipmentRequest request) {
        return ApiResponse.<EquipmentResponse>builder()
                .result(equipmentService.updateEquipment(equipmentId, request))
                .build();
    }

    @DeleteMapping("/equipments/{equipmentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteEquipment(@PathVariable String equipmentId) {
        equipmentService.deleteEquipment(equipmentId);
    }
}
