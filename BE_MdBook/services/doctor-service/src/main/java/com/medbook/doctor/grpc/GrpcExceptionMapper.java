package com.medbook.doctor.grpc;

import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import io.grpc.Status;

final class GrpcExceptionMapper {

    private GrpcExceptionMapper() {
    }

    static Status map(Throwable throwable) {
        if (throwable instanceof AppException appException) {
            ErrorCode errorCode = appException.getErrorCode();
            return switch (errorCode) {
                case DOCTOR_NOT_EXISTED, DOCTOR_SCHEDULE_NOT_EXISTED -> Status.NOT_FOUND.withDescription(errorCode.getMessage());
                case UNAUTHENTICATED -> Status.UNAUTHENTICATED.withDescription(errorCode.getMessage());
                case UNAUTHORIZED -> Status.PERMISSION_DENIED.withDescription(errorCode.getMessage());
                default -> Status.INVALID_ARGUMENT.withDescription(errorCode.getMessage());
            };
        }

        if (throwable instanceof IllegalArgumentException ex) {
            return Status.INVALID_ARGUMENT.withDescription(ex.getMessage());
        }

        return Status.INTERNAL.withDescription("Internal server error");
    }
}
