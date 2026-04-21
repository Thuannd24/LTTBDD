package com.medbook.appointment.client.model;

public record RoomInfo(
        String id,
        String name,
        String category,
        boolean active
) {
}
