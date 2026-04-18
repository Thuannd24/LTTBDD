package com.medbook.slotservice.exception;

import lombok.Getter;

@Getter
public enum ErrorCode {
    SUCCESS(1000, "Success"),
    UNCATEGORIZED_EXCEPTION(1001, "Internal server error"),

    VALIDATION_FAILED(1100, "Validation failed"),
    INVALID_TIME_RANGE(1101, "Start time must be before end time"),
    INVALID_SLOT_DURATION(1102, "Slot duration must be a positive number of minutes"),
    SLOT_NOT_RESERVED(1103, "Slot is not reserved, cannot release"),
    SLOT_CANNOT_BLOCK(1104, "Cannot block a slot that is already reserved"),
    INVALID_TARGET_TYPE(1105, "Invalid target type for requested operation"),

    ROOM_NOT_FOUND(1301, "Room not found"),
    EQUIPMENT_NOT_FOUND(1302, "Equipment not found"),
    SLOT_NOT_FOUND(1303, "Slot not found"),
    RECURRING_CONFIG_NOT_FOUND(1304, "Recurring config not found"),
    TARGET_NOT_FOUND(1305, "Target room or equipment not found"),

    ROOM_CODE_ALREADY_EXISTS(1401, "Room code already exists in this facility"),
    EQUIPMENT_CODE_ALREADY_EXISTS(1402, "Equipment code already exists in this facility"),
    RECURRING_CONFIG_ALREADY_EXISTS(1403, "Recurring config already exists for this target, facility, day and time range"),
    SLOT_ALREADY_RESERVED(1404, "Slot already reserved"),
    ROOM_HAS_EQUIPMENTS(1405, "Room still has equipments and cannot be deleted"),
    SLOT_APPOINTMENT_MISMATCH(1406, "Slot belongs to a different appointment"),

    UNAUTHORIZED(2001, "Unauthorized"),
    FORBIDDEN(2002, "Forbidden"),
    INTERNAL_SERVICE_UNAUTHORIZED(2003, "Missing or invalid X-Internal-Service header");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
}
