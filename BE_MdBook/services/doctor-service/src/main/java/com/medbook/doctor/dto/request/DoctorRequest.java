package com.medbook.doctor.dto.request;

import java.util.Set;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
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
public class DoctorRequest {
    @NotBlank(message = "USER_ID_BLANK")
    String userId;

    Set<String> specialtyIds;

    @Min(value = 0, message = "INVALID_EXPERIENCE")
    int experienceYears;

    @Min(value = 0, message = "INVALID_HOURLY_RATE")
    double hourlyRate;

    String degree;
    String position;
    String workLocation;
    String biography;
    String services;
    String qualification;
    String status;
}
