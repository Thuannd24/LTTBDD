package com.medbook.appointment.client.model;

import java.util.List;

public record DoctorInfo(
        String id,
        String name,
        String specialtyId,
        List<String> allowedSpecialtyIds,
        boolean active
) {
}
