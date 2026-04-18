package com.medbook.slotservice.grpc;

import com.medbook.slotservice.configuration.CustomJwtDecoder;
import io.grpc.Context;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.ServerInterceptor;
import io.grpc.Status;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.server.interceptor.GrpcGlobalServerInterceptor;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.stereotype.Component;

@Component
@GrpcGlobalServerInterceptor
@RequiredArgsConstructor
@Slf4j
public class JwtAuthenticationInterceptor implements ServerInterceptor {

    private static final Metadata.Key<String> AUTHORIZATION_KEY =
            Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER);

    static final Context.Key<Jwt> JWT_CONTEXT_KEY = Context.key("grpc.jwt");

    private final CustomJwtDecoder customJwtDecoder;

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> call,
            Metadata headers,
            ServerCallHandler<ReqT, RespT> next) {
        String authorization = headers.get(AUTHORIZATION_KEY);
        if (authorization == null || authorization.isBlank()) {
            call.close(Status.UNAUTHENTICATED.withDescription("Missing Authorization metadata"), new Metadata());
            return new ServerCall.Listener<>() {
            };
        }

        if (!authorization.startsWith("Bearer ")) {
            call.close(Status.UNAUTHENTICATED.withDescription("Invalid Authorization scheme"), new Metadata());
            return new ServerCall.Listener<>() {
            };
        }

        String token = authorization.substring("Bearer ".length()).trim();
        if (token.isBlank()) {
            call.close(Status.UNAUTHENTICATED.withDescription("Empty bearer token"), new Metadata());
            return new ServerCall.Listener<>() {
            };
        }

        try {
            Jwt jwt = customJwtDecoder.decode(token);
            return Contexts.interceptCall(Context.current().withValue(JWT_CONTEXT_KEY, jwt), call, headers, next);
        } catch (JwtException ex) {
            log.debug("gRPC JWT validation failed: {}", ex.getMessage());
            call.close(Status.UNAUTHENTICATED.withDescription("Invalid bearer token"), new Metadata());
            return new ServerCall.Listener<>() {
            };
        }
    }
}
