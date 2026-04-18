package com.medbook.slotservice.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Lớp cấu hình SecurityConfig.
 * 
 * Mục đích: Đây là "Trái tim" bảo mật của Microservice, đóng vai trò như một Trạm kiểm soát.
 * Hệ thống này không có chức năng Log In mà chỉ đóng vai trò OAuth2 Resource Server. Nhiệm vụ chính là:
 * - Quy định API nào mở cửa tự do (PUBLIC_ENDPOINTS), API nào bắt buộc phải quét token do Gateway ném xuống.
 * - Nhận JWT Token từ Header của Request, đem đi giải mã qua CustomJwtDecoder.
 * - Bóc tách danh sách Quyền (Roles) bọc trong Token của Keycloak để phân quyền hệ thống.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private static final String[] PUBLIC_ENDPOINTS = {
            "/slots/health",
            "/health",
            "/actuator/**",
            "/v3/api-docs/**",
            "/swagger-ui/**",
            "/swagger-ui.html"
    };

    private final CustomJwtDecoder customJwtDecoder;

    public SecurityConfig(CustomJwtDecoder customJwtDecoder) {
        this.customJwtDecoder = customJwtDecoder;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity httpSecurity) throws Exception {
        httpSecurity.authorizeHttpRequests(request -> request
                .requestMatchers(HttpMethod.GET, PUBLIC_ENDPOINTS).permitAll()
                .requestMatchers(HttpMethod.POST, PUBLIC_ENDPOINTS).permitAll()
                .anyRequest()
                .authenticated());

        // Cấu hình để biến Microservice thành "OAuth2 Resource Server".
        // Service này sẽ KHÔNG tự phát hành Token, màn nhận Token từ Gateway -> giải mã -> Mở cổng.
        httpSecurity.oauth2ResourceServer(oauth2 -> oauth2.jwt(jwtConfigurer -> jwtConfigurer
                .decoder(customJwtDecoder) // Chỉ định ống nhòm giải mã là lớp Custom ta vừa config ở trên
                .jwtAuthenticationConverter(jwtAuthenticationConverter()))
                // Thiết lập bẫy bắt Lỗi 401 (Chưa đăng nhập) trả về Object JSON chuẩn dự án
                .authenticationEntryPoint(new JwtAuthenticationEntryPoint()));

        httpSecurity.csrf(AbstractHttpConfigurer::disable);

        return httpSecurity.build();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        
        // Theo chuẩn Security của Keycloak, danh sách quyền (Roles) bị giấu trong khối 'realm_access' của file Token.
        // Springboot không tự chui vào đó tìm được. Hàm này Extract (bóc tách) các role đó ra
        // và tự động đính kèm thêm tiền tố "ROLE_" (Theo luật cú pháp của Spring Framework).
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(jwt -> {
            java.util.Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            if (realmAccess == null || realmAccess.isEmpty()) {
                return java.util.Collections.emptyList();
            }

            java.util.Collection<String> roles = (java.util.Collection<String>) realmAccess.get("roles");
            return roles.stream()
                    .map(role -> new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_" + role))
                    .collect(java.util.stream.Collectors.toList());
        });
        return jwtAuthenticationConverter;
    }
}
