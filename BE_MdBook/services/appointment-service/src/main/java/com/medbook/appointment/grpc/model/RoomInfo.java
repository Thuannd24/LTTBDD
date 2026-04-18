package com.medbook.appointment.grpc.model;

public record RoomInfo(
        String id,
        String name,
        String category,
        boolean active
) {
}
