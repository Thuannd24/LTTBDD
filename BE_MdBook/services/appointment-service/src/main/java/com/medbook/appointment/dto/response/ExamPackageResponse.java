package com.medbook.appointment.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ExamPackageResponse {
    String id;
    String code;
    String name;
    String description;
    String status;
    Integer estimatedTotalMinutes;
    String specialtyId;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
