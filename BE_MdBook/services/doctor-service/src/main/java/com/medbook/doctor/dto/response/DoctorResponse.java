package com.medbook.doctor.dto.response;

import java.time.Instant;
import java.util.Set;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DoctorResponse {
    String id;
    String userId;
    Set<String> specialtyIds;
    int experienceYears;
    double hourlyRate;
    String degree;
    String position;
    String workLocation;
    String biography;
    String services;
    String qualification;
    String status;
    Instant createdAt;
    Instant updatedAt;
}
