package com.medbook.doctor.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

import lombok.Getter;

@Getter
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_KEY(1001, "Uncategorized error", HttpStatus.BAD_REQUEST),
    USER_EXISTED(1002, "User existed", HttpStatus.BAD_REQUEST),
    USERNAME_INVALID(1003, "Username must be at least {min} characters", HttpStatus.BAD_REQUEST),
    INVALID_PASSWORD(1004, "Password must be at least {min} characters", HttpStatus.BAD_REQUEST),
    USER_NOT_EXISTED(1005, "User not existed", HttpStatus.NOT_FOUND),
    UNAUTHENTICATED(1006, "Unauthenticated", HttpStatus.UNAUTHORIZED),
    UNAUTHORIZED(1007, "You do not have permission", HttpStatus.FORBIDDEN),
    INVALID_DOB(1008, "Your age must be at least {min}", HttpStatus.BAD_REQUEST),
    DOCTOR_NOT_EXISTED(1010, "Doctor not existed", HttpStatus.NOT_FOUND),
    SPECIALTY_EXISTED(1011, "Specialty already existed", HttpStatus.BAD_REQUEST),
    SPECIALTY_NOT_EXISTED(1012, "Specialty not existed", HttpStatus.NOT_FOUND),
    NAME_BLANK(1013, "Name must not be blank", HttpStatus.BAD_REQUEST),
    USER_ID_BLANK(1014, "User id must not be blank", HttpStatus.BAD_REQUEST),
    INVALID_EXPERIENCE(1015, "Experience must be greater than or equal to 0", HttpStatus.BAD_REQUEST),
    INVALID_HOURLY_RATE(1016, "Hourly rate must be greater than or equal to 0", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_NOT_EXISTED(1017, "Doctor schedule not existed", HttpStatus.NOT_FOUND),
    DOCTOR_SCHEDULE_OVERLAPPED(1018, "Doctor schedule overlapped", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_INVALID_TIME_RANGE(1019, "Doctor schedule start time must be before end time", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_ALREADY_RESERVED(1020, "Doctor schedule already reserved", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_NOT_RESERVED(1021, "Doctor schedule not reserved", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_CANNOT_BLOCK(1022, "Doctor schedule cannot be blocked", HttpStatus.BAD_REQUEST),
    FACILITY_ID_REQUIRED(1023, "Facility id is required", HttpStatus.BAD_REQUEST),
    START_TIME_REQUIRED(1024, "Start time is required", HttpStatus.BAD_REQUEST),
    END_TIME_REQUIRED(1025, "End time is required", HttpStatus.BAD_REQUEST),
    APPOINTMENT_ID_REQUIRED(1026, "Appointment id is required", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_CANNOT_UPDATE(1027, "Doctor schedule cannot be updated", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_CANNOT_DELETE(1028, "Doctor schedule cannot be deleted", HttpStatus.BAD_REQUEST),
    DOCTOR_SCHEDULE_APPOINTMENT_MISMATCH(1029, "Doctor schedule belongs to a different appointment", HttpStatus.BAD_REQUEST),
    ;

    ErrorCode(int code, String message, HttpStatusCode statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }

    private final int code;
    private final String message;
    private final HttpStatusCode statusCode;
}
