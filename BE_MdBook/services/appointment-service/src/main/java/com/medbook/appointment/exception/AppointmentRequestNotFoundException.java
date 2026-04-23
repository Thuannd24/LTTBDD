package com.medbook.appointment.exception;

public class AppointmentRequestNotFoundException extends RuntimeException {
    public AppointmentRequestNotFoundException(String message) {
        super(message);
    }
}
