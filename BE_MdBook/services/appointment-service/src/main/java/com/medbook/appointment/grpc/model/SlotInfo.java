package com.medbook.appointment.grpc.model;

public record SlotInfo(
        String id,
        String targetType,
        String targetId,
        String date,
        String startTime,
        String endTime,
        boolean available
) {
}
