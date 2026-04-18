package com.medbook.appointment.exception;

public class GrpcUnauthenticatedException extends RuntimeException {
    public GrpcUnauthenticatedException(String message, Throwable cause) {
        super(message, cause);
    }
}