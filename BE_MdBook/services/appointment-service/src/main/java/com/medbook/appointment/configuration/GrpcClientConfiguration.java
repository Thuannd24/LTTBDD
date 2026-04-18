package com.medbook.appointment.configuration;

import com.medbook.appointment.exception.GrpcCommunicationException;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.context.annotation.Configuration;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Configuration
public class GrpcClientConfiguration {

    private final DiscoveryClient discoveryClient;

    private final Map<String, AtomicInteger> serviceCounters = new ConcurrentHashMap<>();

    @Value("${grpc.metadata-grpc-port-key:grpc.port}")
    private String grpcPortMetadataKey;

    public GrpcClientConfiguration(DiscoveryClient discoveryClient) {
        this.discoveryClient = discoveryClient;
    }

    public ManagedChannel createManagedChannel(String serviceId, int defaultGrpcPort) {
        ServiceInstance instance = selectInstance(serviceId);
        int grpcPort = resolveGrpcPort(instance, defaultGrpcPort);

        return ManagedChannelBuilder.forAddress(instance.getHost(), grpcPort)
                .usePlaintext()
                .build();
    }

    private ServiceInstance selectInstance(String serviceId) {
        List<ServiceInstance> instances = discoveryClient.getInstances(serviceId);
        if (instances == null || instances.isEmpty()) {
            throw new GrpcCommunicationException("No instance available in Eureka for service: " + serviceId);
        }

        AtomicInteger counter = serviceCounters.computeIfAbsent(serviceId, key -> new AtomicInteger(0));
        int index = Math.floorMod(counter.getAndIncrement(), instances.size());
        return instances.get(index);
    }

    private int resolveGrpcPort(ServiceInstance instance, int defaultGrpcPort) {
        String metadataPort = findMetadataPort(instance);
        if (metadataPort != null && !metadataPort.isBlank()) {
            try {
                return Integer.parseInt(metadataPort);
            } catch (NumberFormatException ignored) {
                // Fallback to discovered service port or configured default.
            }
        }

        if (instance.getPort() > 0) {
            return instance.getPort();
        }
        return defaultGrpcPort;
    }

    private String findMetadataPort(ServiceInstance instance) {
        Map<String, String> metadata = instance.getMetadata();

        String metadataPort = metadata.get(grpcPortMetadataKey);
        if (metadataPort != null && !metadataPort.isBlank()) {
            return metadataPort;
        }

        String[] fallbackKeys = {"grpc.port", "grpc_port", "grpcPort", "GRPC_PORT"};
        for (String key : fallbackKeys) {
            String value = metadata.get(key);
            if (value != null && !value.isBlank()) {
                return value;
            }
        }

        return null;
    }
}
