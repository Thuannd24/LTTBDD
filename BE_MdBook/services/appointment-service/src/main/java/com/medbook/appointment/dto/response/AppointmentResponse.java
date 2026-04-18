package com.medbook.appointment.dto.response;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppointmentResponse {
    
    String id;
    
    String sagaId;
    
    String patientUserId;
    
    String doctorId;
    
    Long doctorScheduleId;
    
    String facilityId;
    
    String packageId;
    
    String packageStepId;
    
    String status;
    
    String note;
    
    String cancelReason;
    
    String failureCode;
    
    String failureMessage;
    
    LocalDateTime createdAt;
    
    LocalDateTime updatedAt;
}
