package com.medbook.doctor.messaging;

public final class RabbitTopology {

    public static final String APPOINTMENT_EXCHANGE = "appointment-exchange";
    public static final String DOCTOR_COMMAND_QUEUE = "doctor-command-queue";

    private RabbitTopology() {
    }

    public static String replyRoutingKey(SagaEventType eventType) {
        return switch (eventType) {
            case DOCTOR_RESERVED -> "appointment.reply.doctor.reserved";
            case DOCTOR_RESERVE_FAILED -> "appointment.reply.doctor.reserve-failed";
            case DOCTOR_RELEASED -> "appointment.reply.doctor.released";
            case DOCTOR_RELEASE_FAILED -> "appointment.reply.doctor.release-failed";
            default -> throw new IllegalArgumentException("Unsupported doctor reply event: " + eventType);
        };
    }
}
