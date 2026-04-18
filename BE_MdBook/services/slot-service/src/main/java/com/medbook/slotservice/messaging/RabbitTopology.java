package com.medbook.slotservice.messaging;

public final class RabbitTopology {

    public static final String APPOINTMENT_EXCHANGE = "appointment-exchange";
    public static final String SLOT_COMMAND_QUEUE = "slot-command-queue";

    private RabbitTopology() {
    }

    public static String replyRoutingKey(SagaEventType eventType) {
        return switch (eventType) {
            case ROOM_SLOT_RESERVED -> "appointment.reply.slot.room.reserved";
            case ROOM_SLOT_RESERVE_FAILED -> "appointment.reply.slot.room.reserve-failed";
            case EQUIPMENT_SLOT_RESERVED -> "appointment.reply.slot.equipment.reserved";
            case EQUIPMENT_SLOT_RESERVE_FAILED -> "appointment.reply.slot.equipment.reserve-failed";
            case ROOM_SLOT_RELEASED -> "appointment.reply.slot.room.released";
            case ROOM_SLOT_RELEASE_FAILED -> "appointment.reply.slot.room.release-failed";
            case EQUIPMENT_SLOT_RELEASED -> "appointment.reply.slot.equipment.released";
            case EQUIPMENT_SLOT_RELEASE_FAILED -> "appointment.reply.slot.equipment.release-failed";
            default -> throw new IllegalArgumentException("Unsupported slot reply event: " + eventType);
        };
    }
}
