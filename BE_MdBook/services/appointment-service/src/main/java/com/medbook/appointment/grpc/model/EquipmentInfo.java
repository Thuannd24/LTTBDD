package com.medbook.appointment.grpc.model;

public record EquipmentInfo(
        String id,
        String name,
        String type,
        boolean active
) {
}
