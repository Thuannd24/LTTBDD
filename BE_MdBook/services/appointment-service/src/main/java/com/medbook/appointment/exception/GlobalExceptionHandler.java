package com.medbook.appointment.exception;

import com.medbook.appointment.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({
            AppointmentNotFoundException.class,
            DoctorNotFoundException.class,
            RoomNotFoundException.class,
            EquipmentNotFoundException.class,
            SlotNotFoundException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleNotFound(RuntimeException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, 1404, ex.getMessage());
    }

    @ExceptionHandler({
            DoctorScheduleNotFoundException.class,
            AppointmentValidationException.class,
            MethodArgumentNotValidException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleBadRequest(Exception ex) {
        String message = ex.getMessage();
        if (ex instanceof MethodArgumentNotValidException methodArgumentNotValidException
                && methodArgumentNotValidException.getBindingResult().getFieldError() != null) {
            message = methodArgumentNotValidException.getBindingResult().getFieldError().getDefaultMessage();
        }
        return buildResponse(HttpStatus.BAD_REQUEST, 1400, message);
    }

    @ExceptionHandler(GrpcPermissionDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handlePermissionDenied(GrpcPermissionDeniedException ex) {
        return buildResponse(HttpStatus.FORBIDDEN, 1403, ex.getMessage());
    }

    @ExceptionHandler(GrpcUnauthenticatedException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnauthenticated(GrpcUnauthenticatedException ex) {
        return buildResponse(HttpStatus.UNAUTHORIZED, 1401, ex.getMessage());
    }

    @ExceptionHandler(AppointmentAccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAppointmentAccessDenied(AppointmentAccessDeniedException ex) {
        return buildResponse(HttpStatus.FORBIDDEN, 1403, ex.getMessage());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        return buildResponse(HttpStatus.FORBIDDEN, 1403, ex.getMessage());
    }

    @ExceptionHandler(GrpcCommunicationException.class)
    public ResponseEntity<ApiResponse<Void>> handleGrpcCommunication(GrpcCommunicationException ex) {
        return buildResponse(HttpStatus.SERVICE_UNAVAILABLE, 1503, ex.getMessage());
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnhandled(RuntimeException ex) {
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, 1500, ex.getMessage());
    }

    private ResponseEntity<ApiResponse<Void>> buildResponse(HttpStatus status, int code, String message) {
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .code(code)
                .message(message)
                .build();
        return ResponseEntity.status(status).body(response);
    }
}
