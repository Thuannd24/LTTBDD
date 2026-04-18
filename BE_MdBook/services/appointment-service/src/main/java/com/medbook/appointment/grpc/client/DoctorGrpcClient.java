package com.medbook.appointment.grpc.client;

import com.medbook.appointment.configuration.GrpcClientConfiguration;
import com.medbook.appointment.configuration.GrpcProperties;
import com.medbook.appointment.exception.DoctorNotFoundException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.exception.GrpcCommunicationException;
import com.medbook.appointment.exception.GrpcPermissionDeniedException;
import com.medbook.appointment.exception.GrpcUnauthenticatedException;
import com.medbook.appointment.grpc.interceptor.AuthenticationInterceptor;
import com.medbook.appointment.grpc.interceptor.ErrorHandlingInterceptor;
import com.medbook.appointment.grpc.model.DoctorInfo;
import com.medbook.appointment.grpc.model.DoctorScheduleInfo;
import com.medbook.grpc.doctor.DoctorResponse;
import com.medbook.grpc.doctor.DoctorScheduleResponse;
import com.medbook.grpc.doctor.DoctorServiceGrpc;
import com.medbook.grpc.doctor.GetDoctorByIdRequest;
import com.medbook.grpc.doctor.GetDoctorScheduleByIdRequest;
import io.grpc.ClientInterceptors;
import io.grpc.ManagedChannel;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class DoctorGrpcClient {

    GrpcClientConfiguration grpcClientConfiguration;
    AuthenticationInterceptor authenticationInterceptor;
    ErrorHandlingInterceptor errorHandlingInterceptor;
    GrpcProperties grpcProperties;

    public DoctorInfo getDoctorById(String doctorId) {
        ManagedChannel channel = grpcClientConfiguration.createManagedChannel(
                grpcProperties.getDoctorServiceId(), grpcProperties.getDoctorDefaultGrpcPort());
        try {
            DoctorServiceGrpc.DoctorServiceBlockingStub stub = DoctorServiceGrpc.newBlockingStub(
                    ClientInterceptors.intercept(channel, authenticationInterceptor, errorHandlingInterceptor));

            DoctorResponse response = stub
                    .withDeadlineAfter(grpcProperties.getCallTimeoutSeconds(), TimeUnit.SECONDS)
                    .getDoctorById(GetDoctorByIdRequest.newBuilder().setDoctorId(doctorId).build());

            if (response.getId().isBlank()) {
                throw new DoctorNotFoundException("Doctor not found: " + doctorId);
            }

            return new DoctorInfo(
                    response.getId(),
                    response.getName(),
                    response.getSpecialtyId(),
                    response.getAllowedSpecialtyIdsList(),
                    response.getActive());
        } catch (StatusRuntimeException ex) {
            throw mapDoctorException(ex, doctorId);
        } finally {
            channel.shutdownNow();
        }
    }

    public DoctorScheduleInfo getDoctorScheduleById(String scheduleId, String doctorId) {
        ManagedChannel channel = grpcClientConfiguration.createManagedChannel(
                grpcProperties.getDoctorServiceId(), grpcProperties.getDoctorDefaultGrpcPort());
        try {
            DoctorServiceGrpc.DoctorServiceBlockingStub stub = DoctorServiceGrpc.newBlockingStub(
                    ClientInterceptors.intercept(channel, authenticationInterceptor, errorHandlingInterceptor));

            DoctorScheduleResponse response = stub
                    .withDeadlineAfter(grpcProperties.getCallTimeoutSeconds(), TimeUnit.SECONDS)
                    .getDoctorScheduleById(GetDoctorScheduleByIdRequest.newBuilder()
                            .setScheduleId(scheduleId)
                            .setDoctorId(doctorId)
                            .build());

            if (response.getId().isBlank()) {
                throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
            }

            return new DoctorScheduleInfo(
                    response.getId(),
                    response.getDoctorId(),
                    response.getDate(),
                    response.getStartTime(),
                    response.getEndTime(),
                    response.getAvailable());
        } catch (StatusRuntimeException ex) {
            throw mapDoctorScheduleException(ex, scheduleId);
        } finally {
            channel.shutdownNow();
        }
    }

    RuntimeException mapDoctorException(StatusRuntimeException ex, String doctorId) {
        Status.Code code = ex.getStatus().getCode();
        String description = ex.getStatus().getDescription();

        if (code == Status.Code.NOT_FOUND) return new DoctorNotFoundException("Doctor not found: " + doctorId);
        if (code == Status.Code.PERMISSION_DENIED) return new GrpcPermissionDeniedException(buildGrpcMessage("Permission denied when calling doctor-service", description), ex);
        if (code == Status.Code.UNAUTHENTICATED) return new GrpcUnauthenticatedException(buildGrpcMessage("Unauthenticated when calling doctor-service", description), ex);
        if (code == Status.Code.INVALID_ARGUMENT) return new GrpcCommunicationException(buildGrpcMessage("Invalid request when calling doctor-service", description), ex);
        if (code == Status.Code.DEADLINE_EXCEEDED || code == Status.Code.UNAVAILABLE) return new GrpcCommunicationException(buildGrpcMessage("Doctor-service unavailable", description), ex);
        return new GrpcCommunicationException(buildGrpcMessage("Error calling doctor-service", description), ex);
    }

    RuntimeException mapDoctorScheduleException(StatusRuntimeException ex, String scheduleId) {
        Status.Code code = ex.getStatus().getCode();
        String description = ex.getStatus().getDescription();

        if (code == Status.Code.NOT_FOUND) return new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
        if (code == Status.Code.PERMISSION_DENIED) return new GrpcPermissionDeniedException(buildGrpcMessage("Permission denied when calling doctor-service", description), ex);
        if (code == Status.Code.UNAUTHENTICATED) return new GrpcUnauthenticatedException(buildGrpcMessage("Unauthenticated when calling doctor-service", description), ex);
        if (code == Status.Code.INVALID_ARGUMENT) return new GrpcCommunicationException(buildGrpcMessage("Invalid request when calling doctor-service", description), ex);
        if (code == Status.Code.DEADLINE_EXCEEDED || code == Status.Code.UNAVAILABLE) return new GrpcCommunicationException(buildGrpcMessage("Doctor-service unavailable", description), ex);
        return new GrpcCommunicationException(buildGrpcMessage("Error calling doctor-service", description), ex);
    }

    private String buildGrpcMessage(String baseMessage, String description) {
        if (description == null || description.isBlank()) {
            return baseMessage;
        }
        return baseMessage + ": " + description;
    }
}
