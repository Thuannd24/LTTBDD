package com.medbook.appointment.client.model;

public record EquipmentInfo(
        String id,
        String name,
        String type,
        boolean active
) {
}
