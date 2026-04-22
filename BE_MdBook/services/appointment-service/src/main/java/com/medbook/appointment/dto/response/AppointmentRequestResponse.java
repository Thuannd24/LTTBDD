package com.medbook.appointment.dto.response;

import java.time.LocalDateTime;
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
public class AppointmentRequestResponse {

    String id;
    String patientUserId;
    String doctorId;
    Long doctorScheduleId;
    String packageId;
    String facilityId;
    Long roomSlotId;
    Long equipmentSlotId;
    String status;
    String note;
    String appointmentId;
    String processedBy;
    LocalDateTime processedAt;
    String rejectionReason;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
