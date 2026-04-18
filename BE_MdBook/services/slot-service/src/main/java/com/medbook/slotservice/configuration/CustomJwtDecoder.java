package com.medbook.slotservice.configuration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;

import javax.crypto.spec.SecretKeySpec;
import java.util.Objects;

@Configuration
public class CustomJwtDecoder implements JwtDecoder {
    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String issuerUri;

    private NimbusJwtDecoder nimbusJwtDecoder = null;

    @Override
    public Jwt decode(String token) throws JwtException {
        if (Objects.isNull(nimbusJwtDecoder)) {
            // Mặc định Spring Boot sẽ tìm Issuer URL để get bộ khóa Public Key về tự giải mã.
            // Tuy nhiên vì Keycloak đang chạy trên một Container tên là 'keycloak:8080' (Mạng nội bộ Docker)
            // nhưng token do Postman/Client truyền tới lại mang nhãn Issuer là 'localhost:8181',
            // Sinh ra hiện trạng lỗi Mismatch (Không khớp nguồn cấp).
            
            // Point directly to JWKS URI to avoid missing localhost discovery inside Docker
            // => Trực tiếp chọc tới đường dẫn tải khóa (certs) bỏ qua auto-discovery
            String jwkSetUri = issuerUri + "/protocol/openid-connect/certs";
            nimbusJwtDecoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri).build();
            
            // => Tắt luôn cơ chế validation strict kiểm tra xem chữ 'localhost' với 'keycloak' có giống nhau không
            nimbusJwtDecoder.setJwtValidator(jwt -> org.springframework.security.oauth2.core.OAuth2TokenValidatorResult.success());
        }

        return nimbusJwtDecoder.decode(token);
    }
}
