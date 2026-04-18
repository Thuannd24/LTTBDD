package com.identityservice.configuration;

import java.util.Objects;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;

import lombok.experimental.NonFinal;

@Component
public class CustomJwtDecoder implements JwtDecoder {
    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String issuerUri;

    @NonFinal
    private NimbusJwtDecoder nimbusJwtDecoder = null;

    @Override
    public Jwt decode(String token) throws JwtException {
        if (Objects.isNull(nimbusJwtDecoder)) {
            String jwkSetUri = issuerUri + "/protocol/openid-connect/certs";
            nimbusJwtDecoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri).build();
            nimbusJwtDecoder.setJwtValidator(jwt -> OAuth2TokenValidatorResult.success());
        }

        return nimbusJwtDecoder.decode(token);
    }
}
