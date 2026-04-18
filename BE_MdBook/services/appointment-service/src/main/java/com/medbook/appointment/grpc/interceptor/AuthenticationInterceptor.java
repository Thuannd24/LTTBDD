package com.medbook.appointment.grpc.interceptor;

import com.medbook.appointment.grpc.context.JwtContextHolder;
import io.grpc.CallOptions;
import io.grpc.Channel;
import io.grpc.ClientCall;
import io.grpc.ClientInterceptor;
import io.grpc.ForwardingClientCall;
import io.grpc.Metadata;
import io.grpc.MethodDescriptor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class AuthenticationInterceptor implements ClientInterceptor {

    private static final Metadata.Key<String> AUTHORIZATION_KEY =
            Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER);

    @Override
    public <ReqT, RespT> ClientCall<ReqT, RespT> interceptCall(MethodDescriptor<ReqT, RespT> method,
                                                                CallOptions callOptions,
                                                                Channel next) {
        return new ForwardingClientCall.SimpleForwardingClientCall<>(next.newCall(method, callOptions)) {
            @Override
            public void start(Listener<RespT> responseListener, Metadata headers) {
                String token = JwtContextHolder.getToken();
                if (token != null && !token.isBlank()) {
                    String bearerToken = token.startsWith("Bearer ") ? token : "Bearer " + token;
                    headers.put(AUTHORIZATION_KEY, bearerToken);
                }
                log.debug("gRPC call: {}", method.getFullMethodName());
                super.start(responseListener, headers);
            }
        };
    }
}
