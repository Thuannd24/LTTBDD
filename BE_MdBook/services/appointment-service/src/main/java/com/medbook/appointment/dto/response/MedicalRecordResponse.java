package com.medbook.appointment.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class MedicalRecordResponse {

    String id;
    String appointmentId;
    String patientUserId;
    String doctorId;
    String diagnosis;
    String symptoms;
    String prescription;
    String notes;
    String aiSummary;
    LocalDateTime followUpDate;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
