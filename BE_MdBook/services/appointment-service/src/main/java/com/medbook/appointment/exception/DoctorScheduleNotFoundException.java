package com.medbook.appointment.exception;

public class DoctorScheduleNotFoundException extends RuntimeException {
    public DoctorScheduleNotFoundException(String message) {
        super(message);
    }
}
