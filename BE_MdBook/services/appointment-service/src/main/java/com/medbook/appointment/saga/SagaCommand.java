package com.medbook.appointment.saga;

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
public class SagaCommand {

    String messageId;
    String appointmentId;
    String sagaId;
    SagaEventType eventType;
    String patientUserId;
    String facilityId;
    String doctorId;
    Long doctorScheduleId;
    Long roomSlotId;
    Long equipmentSlotId;
}
