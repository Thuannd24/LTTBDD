package com.medbook.appointment.client.model;

public record DoctorScheduleInfo(
        String id,
        String doctorId,
        String date,
        String startTime,
        String endTime,
        boolean available
) {
}
