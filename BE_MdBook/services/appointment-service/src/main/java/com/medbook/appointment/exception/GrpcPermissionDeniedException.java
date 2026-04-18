package com.medbook.appointment.exception;

public class GrpcPermissionDeniedException extends RuntimeException {
    public GrpcPermissionDeniedException(String message, Throwable cause) {
        super(message, cause);
    }
}
