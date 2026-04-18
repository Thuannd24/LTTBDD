package com.medbook.slotservice.grpc;

import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import io.grpc.Status;

final class GrpcExceptionMapper {

    private GrpcExceptionMapper() {
    }

    static Status map(Throwable throwable) {
        if (throwable instanceof AppException appException) {
            ErrorCode errorCode = appException.getErrorCode();
            return switch (errorCode) {
                case ROOM_NOT_FOUND, EQUIPMENT_NOT_FOUND, SLOT_NOT_FOUND, TARGET_NOT_FOUND -> Status.NOT_FOUND.withDescription(errorCode.getMessage());
                case UNAUTHORIZED, FORBIDDEN, INTERNAL_SERVICE_UNAUTHORIZED -> Status.PERMISSION_DENIED.withDescription(errorCode.getMessage());
                default -> Status.INVALID_ARGUMENT.withDescription(errorCode.getMessage());
            };
        }

        if (throwable instanceof IllegalArgumentException ex) {
            return Status.INVALID_ARGUMENT.withDescription(ex.getMessage());
        }

        return Status.INTERNAL.withDescription("Internal server error");
    }
}
