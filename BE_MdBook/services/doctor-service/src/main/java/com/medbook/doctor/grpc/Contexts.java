package com.medbook.doctor.grpc;

import io.grpc.Context;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;

final class Contexts {

    private Contexts() {
    }

    static <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            Context context,
            ServerCall<ReqT, RespT> call,
            Metadata headers,
            ServerCallHandler<ReqT, RespT> next) {
        Context previous = context.attach();
        try {
            return next.startCall(call, headers);
        } finally {
            context.detach(previous);
        }
    }
}
