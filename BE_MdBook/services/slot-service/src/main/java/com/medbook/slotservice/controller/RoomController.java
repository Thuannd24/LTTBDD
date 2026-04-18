package com.medbook.slotservice.controller;

import com.medbook.slotservice.dto.ApiResponse;
import com.medbook.slotservice.dto.request.CreateRoomRequest;
import com.medbook.slotservice.dto.request.UpdateRoomRequest;
import com.medbook.slotservice.dto.response.RoomResponse;
import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import com.medbook.slotservice.service.RoomService;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<RoomResponse> createRoom(@Valid @RequestBody CreateRoomRequest request) {
        return ApiResponse.<RoomResponse>builder().result(roomService.createRoom(request)).build();
    }

    @GetMapping("/{roomId}")
    public ApiResponse<RoomResponse> getRoom(@PathVariable String roomId) {
        return ApiResponse.<RoomResponse>builder().result(roomService.getRoom(roomId)).build();
    }

    @GetMapping
    public ApiResponse<List<RoomResponse>> listRooms(
            @RequestParam(required = false) Long facilityId,
            @RequestParam(required = false) RoomCategory roomCategory,
            @RequestParam(required = false) RoomStatus status) {
        return ApiResponse.<List<RoomResponse>>builder()
                .result(roomService.listRooms(facilityId, roomCategory, status))
                .build();
    }

    @PutMapping("/{roomId}")
    public ApiResponse<RoomResponse> updateRoom(
            @PathVariable String roomId,
            @Valid @RequestBody UpdateRoomRequest request) {
        return ApiResponse.<RoomResponse>builder().result(roomService.updateRoom(roomId, request)).build();
    }

    @DeleteMapping("/{roomId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoom(@PathVariable String roomId) {
        roomService.deleteRoom(roomId);
    }
}
