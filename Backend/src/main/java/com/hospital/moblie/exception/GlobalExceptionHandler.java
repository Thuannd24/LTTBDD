package com.hospital.moblie.exception;

import org.springframework.web.bind.annotation.RestControllerAdvice;
import com.hospital.moblie.dto.ApiResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.http.HttpStatus;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.http.ResponseEntity;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiResponse<Void> handleResourceNotFoundException(ResourceNotFoundException ex) {
        return new ApiResponse<>("error", ex.getMessage(), null);
    }

    @ExceptionHandler(BadRequestException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Void> handleBadRequestException(BadRequestException ex) {
        return new ApiResponse<>("error", ex.getMessage(), null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult()
            .getFieldErrors()
            .forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage())
            );

        ApiResponse<Map<String, String>> apiResponse = new ApiResponse<>(
            "error",
            "Validation Failed",
            errors
        );
        return ResponseEntity.badRequest().body(apiResponse);
    }
}