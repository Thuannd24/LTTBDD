package com.medbook.doctor.grpc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.doctor.configuration.CustomJwtDecoder;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.Status;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationInterceptorTest {

    @Mock
    private CustomJwtDecoder customJwtDecoder;

    @Mock
    private ServerCall<String, String> serverCall;

    @Mock
    private ServerCallHandler<String, String> serverCallHandler;

    private JwtAuthenticationInterceptor interceptor;

    @BeforeEach
    void setUp() {
        interceptor = new JwtAuthenticationInterceptor(customJwtDecoder);
    }

    @Test
    void interceptCall_allowsValidBearerToken() {
        Metadata headers = new Metadata();
        headers.put(Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER), "Bearer token-123");
        when(customJwtDecoder.decode("token-123")).thenReturn(mock(Jwt.class));
        when(serverCallHandler.startCall(serverCall, headers)).thenReturn(new ServerCall.Listener<>() {
        });

        interceptor.interceptCall(serverCall, headers, serverCallHandler);

        verify(serverCallHandler).startCall(serverCall, headers);
        verify(serverCall, never()).close(any(), any());
    }

    @Test
    void interceptCall_rejectsMissingToken() {
        interceptor.interceptCall(serverCall, new Metadata(), serverCallHandler);

        ArgumentCaptor<Status> statusCaptor = ArgumentCaptor.forClass(Status.class);
        verify(serverCall).close(statusCaptor.capture(), any());
        assertThat(statusCaptor.getValue().getCode()).isEqualTo(Status.Code.UNAUTHENTICATED);
        verify(serverCallHandler, never()).startCall(any(), any());
    }

    @Test
    void interceptCall_rejectsInvalidToken() {
        Metadata headers = new Metadata();
        headers.put(Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER), "Bearer bad-token");
        when(customJwtDecoder.decode("bad-token")).thenThrow(new JwtException("bad token"));

        interceptor.interceptCall(serverCall, headers, serverCallHandler);

        ArgumentCaptor<Status> statusCaptor = ArgumentCaptor.forClass(Status.class);
        verify(serverCall).close(statusCaptor.capture(), any());
        assertThat(statusCaptor.getValue().getCode()).isEqualTo(Status.Code.UNAUTHENTICATED);
        verify(serverCallHandler, never()).startCall(any(), any());
    }
}
