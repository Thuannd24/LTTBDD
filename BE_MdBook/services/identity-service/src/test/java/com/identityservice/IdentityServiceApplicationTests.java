package com.identityservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "spring.cloud.discovery.enabled=false",
    "spring.cloud.config.enabled=false",
    "eureka.client.enabled=false",
    "spring.security.oauth2.resourceserver.jwt.issuer-uri=http://localhost:8181/realms/clinic-realm",
    "app.keycloak.server-url=http://localhost:8181"
})
class IdentityServiceApplicationTests {

    @Test
    void contextLoads() {
        // Test if the application context starts correctly with the current Keycloak configuration.
    }
}
