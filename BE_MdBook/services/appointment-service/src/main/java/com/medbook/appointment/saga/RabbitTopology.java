package com.medbook.appointment.saga;

public final class RabbitTopology {

    public static final String APPOINTMENT_EXCHANGE = "appointment-exchange";
    public static final String DOCTOR_COMMAND_QUEUE = "doctor-command-queue";
    public static final String SLOT_COMMAND_QUEUE = "slot-command-queue";
    public static final String APPOINTMENT_REPLY_QUEUE = "appointment-reply-queue";

    public static final String DOCTOR_COMMAND_ROUTING_PATTERN = "appointment.command.doctor.#";
    public static final String SLOT_COMMAND_ROUTING_PATTERN = "appointment.command.slot.#";
    public static final String APPOINTMENT_REPLY_ROUTING_PATTERN = "appointment.reply.#";

    private RabbitTopology() {
    }

    public static String routingKeyFor(SagaEventType eventType) {
        return switch (eventType) {
            case DOCTOR_RESERVE_COMMAND -> "appointment.command.doctor.reserve";
            case DOCTOR_RELEASE_COMMAND -> "appointment.command.doctor.release";
            case ROOM_SLOT_RESERVE_COMMAND -> "appointment.command.slot.reserve.room";
            case ROOM_SLOT_RELEASE_COMMAND -> "appointment.command.slot.release.room";
            case EQUIPMENT_SLOT_RESERVE_COMMAND -> "appointment.command.slot.reserve.equipment";
            case EQUIPMENT_SLOT_RELEASE_COMMAND -> "appointment.command.slot.release.equipment";
            case APPOINTMENT_BOOKED -> "appointment.event.booked";
            case APPOINTMENT_CANCELLED -> "appointment.event.cancelled";
            default -> throw new IllegalArgumentException("Unsupported routing for event type: " + eventType);
        };
    }
}
