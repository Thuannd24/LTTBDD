package com.medbook.doctor.dto.response;

import java.time.Instant;

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
public class SpecialtyResponse {
    String id;
    String name;
    String description;
    String overview;
    String services;
    String technology;
    String image;
    Instant createdAt;
    Instant updatedAt;
}
