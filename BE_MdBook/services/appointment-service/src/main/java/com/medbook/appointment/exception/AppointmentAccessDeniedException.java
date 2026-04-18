package com.medbook.appointment.exception;

public class AppointmentAccessDeniedException extends RuntimeException {

    public AppointmentAccessDeniedException(String message) {
        super(message);
    }
}
