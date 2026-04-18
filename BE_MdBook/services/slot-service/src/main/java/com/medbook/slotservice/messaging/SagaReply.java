package com.medbook.slotservice.messaging;

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
public class SagaReply {

    String messageId;
    String appointmentId;
    String sagaId;
    SagaEventType eventType;
    Long roomSlotId;
    Long equipmentSlotId;
    String errorCode;
    String errorMessage;
}
