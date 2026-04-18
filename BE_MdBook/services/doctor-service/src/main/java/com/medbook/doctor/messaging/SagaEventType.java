package com.medbook.doctor.messaging;

public enum SagaEventType {
    DOCTOR_RESERVE_COMMAND,
    DOCTOR_RELEASE_COMMAND,
    DOCTOR_RESERVED,
    DOCTOR_RESERVE_FAILED,
    DOCTOR_RELEASED,
    DOCTOR_RELEASE_FAILED
}
