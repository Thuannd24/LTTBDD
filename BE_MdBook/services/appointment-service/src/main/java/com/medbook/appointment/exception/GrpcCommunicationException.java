package com.medbook.appointment.exception;

public class GrpcCommunicationException extends RuntimeException {
    public GrpcCommunicationException(String message) {
        super(message);
    }

    public GrpcCommunicationException(String message, Throwable cause) {
        super(message, cause);
    }
}
