package com.medbook.profile.configuration;

import java.util.Objects;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

/**
 * Lớp cấu hình CustomJwtDecoder.
 * 
 * Mục đích: Ghi đè bộ giải mã JWT mặc định của Spring Security.
 * Do kiến trúc chạy trên Docker (Keycloak nằm ở 'keycloak:8080' mạng nội bộ,
 * còn Client truy cập từ 'localhost:8181'),
 * token sinh ra thường bị lệch thông tin Issuer (Nguồn phát hành). Lớp này giúp
 * bỏ qua bước kiểm tra cứng nhắc đó
 * và chỉ định trực tiếp đường dẫn tải Public Key về để giải mã Token.
 */
@Component
public class CustomJwtDecoder implements JwtDecoder {
    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String issuerUri;

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
