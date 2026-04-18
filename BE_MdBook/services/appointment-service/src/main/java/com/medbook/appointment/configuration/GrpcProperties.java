package com.medbook.appointment.configuration;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "grpc")
public class GrpcProperties {

    /** Timeout for all gRPC calls in seconds */
    private long callTimeoutSeconds = 5;

    /** Eureka service ID of the doctor-service */
    private String doctorServiceId = "doctor-service";

    /** Default gRPC port for doctor-service (used as fallback) */
    private int doctorDefaultGrpcPort = 50051;

    /** Eureka service ID of the slot-service */
    private String slotServiceId = "slot-service";

    /** Default gRPC port for slot-service (used as fallback) */
    private int slotDefaultGrpcPort = 50052;
}
