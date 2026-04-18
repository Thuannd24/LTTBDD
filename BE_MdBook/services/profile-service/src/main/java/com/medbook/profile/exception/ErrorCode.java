package com.medbook.profile.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

import lombok.Getter;

@Getter
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_KEY(1001, "Uncategorized error", HttpStatus.BAD_REQUEST),
    UNAUTHENTICATED(1006, "Unauthenticated", HttpStatus.UNAUTHORIZED),
    UNAUTHORIZED(1007, "You do not have permission", HttpStatus.FORBIDDEN),
    PROFILE_NOT_FOUND(2001, "Profile not found", HttpStatus.NOT_FOUND),
    PROFILE_ALREADY_EXISTS(2002, "Profile already exists", HttpStatus.CONFLICT),
    INVALID_DOB(2003, "Date of birth must be in the past", HttpStatus.BAD_REQUEST),
    INVALID_PHONE(2004, "Invalid phone number format", HttpStatus.BAD_REQUEST),
    INVALID_GENDER(2005, "Invalid gender value", HttpStatus.BAD_REQUEST),
    USER_ID_REQUIRED(2006, "User ID is required", HttpStatus.BAD_REQUEST),
    INVALID_FIRST_NAME(2007, "First name is too long (max 100 characters)", HttpStatus.BAD_REQUEST),
    INVALID_LAST_NAME(2008, "Last name is too long (max 100 characters)", HttpStatus.BAD_REQUEST),
    INVALID_ADDRESS(2009, "Address is too long (max 255 characters)", HttpStatus.BAD_REQUEST),
    INVALID_INSURANCE_NUMBER(2010, "Insurance number is too long (max 50 characters)", HttpStatus.BAD_REQUEST),
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
