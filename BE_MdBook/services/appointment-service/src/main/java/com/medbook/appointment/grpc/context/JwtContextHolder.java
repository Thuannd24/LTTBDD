package com.medbook.appointment.grpc.context;

public final class JwtContextHolder {
    private static final ThreadLocal<String> JWT_TOKEN = new ThreadLocal<>();

    private JwtContextHolder() {
    }

    public static void setToken(String token) {
        JWT_TOKEN.set(token);
    }

    public static String getToken() {
        return JWT_TOKEN.get();
    }

    public static void clear() {
        JWT_TOKEN.remove();
    }
}
