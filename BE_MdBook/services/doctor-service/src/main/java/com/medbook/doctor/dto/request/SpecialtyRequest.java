package com.medbook.doctor.dto.request;

import java.time.Instant;

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
public class SpecialtyRequest {
    @NotBlank(message = "NAME_BLANK")
    String name;

    String description;
    String overview;
    String services;
    String technology;
    String image;
    Instant createdAt;
    Instant updatedAt;
}
