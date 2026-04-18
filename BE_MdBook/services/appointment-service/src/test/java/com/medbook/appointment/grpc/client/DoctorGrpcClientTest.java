package com.medbook.appointment.grpc.client;

import com.medbook.appointment.configuration.GrpcClientConfiguration;
import com.medbook.appointment.configuration.GrpcProperties;
import com.medbook.appointment.exception.GrpcCommunicationException;
import com.medbook.appointment.exception.GrpcUnauthenticatedException;
import com.medbook.appointment.grpc.interceptor.AuthenticationInterceptor;
import com.medbook.appointment.grpc.interceptor.ErrorHandlingInterceptor;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class DoctorGrpcClientTest {

    @Mock
    private GrpcClientConfiguration grpcClientConfiguration;

    @Mock
    private AuthenticationInterceptor authenticationInterceptor;

    @Mock
    private ErrorHandlingInterceptor errorHandlingInterceptor;

    @Mock
    private GrpcProperties grpcProperties;

    @InjectMocks
    private DoctorGrpcClient doctorGrpcClient;

    private StatusRuntimeException unauthenticatedException;
    private StatusRuntimeException unknownException;

    @BeforeEach
    void setUp() {
        unauthenticatedException = Status.UNAUTHENTICATED.withDescription("Missing Authorization metadata").asRuntimeException();
        unknownException = Status.UNKNOWN.withDescription("Unexpected error").asRuntimeException();
    }

    @Test
    void mapDoctorException_returnsUnauthenticatedWithDescription() {
        RuntimeException exception = doctorGrpcClient.mapDoctorException(unauthenticatedException, "doctor-123");

        assertThat(exception).isInstanceOf(GrpcUnauthenticatedException.class);
        assertThat(exception.getMessage()).contains("Unauthenticated when calling doctor-service");
        assertThat(exception.getMessage()).contains("Missing Authorization metadata");
    }

    @Test
    void mapDoctorScheduleException_includesGrpcDescriptionInFallbackMessage() {
        RuntimeException exception = doctorGrpcClient.mapDoctorScheduleException(unknownException, "schedule-123");

        assertThat(exception).isInstanceOf(GrpcCommunicationException.class);
        assertThat(exception.getMessage()).contains("Error calling doctor-service");
        assertThat(exception.getMessage()).contains("Unexpected error");
    }
}