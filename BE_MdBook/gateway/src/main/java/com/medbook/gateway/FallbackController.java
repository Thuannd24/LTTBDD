package com.medbook.gateway;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Fallback Controller — được gọi khi Circuit Breaker mở (service down).
 * Trả về JSON thông báo lỗi thân thiện thay vì lỗi 500 hoặc timeout.
 */
@RestController
@RequestMapping("/fallback")
public class FallbackController {

    @RequestMapping("/identity")
    public ResponseEntity<Map<String, Object>> identityFallback() {
        return buildFallback("identity-service", "Dịch vụ xác thực tạm thời không khả dụng.");
    }

    @RequestMapping("/profile")
    public ResponseEntity<Map<String, Object>> profileFallback() {
        return buildFallback("profile-service", "Dịch vụ hồ sơ người dùng tạm thời không khả dụng.");
    }

    @RequestMapping("/doctor")
    public ResponseEntity<Map<String, Object>> doctorFallback() {
        return buildFallback("doctor-service", "Dịch vụ thông tin bác sĩ tạm thời không khả dụng.");
    }

    @RequestMapping("/appointment")
    public ResponseEntity<Map<String, Object>> appointmentFallback() {
        return buildFallback("appointment-service", "Dịch vụ đặt lịch tạm thời không khả dụng. Vui lòng thử lại sau.");
    }

    @RequestMapping("/slot")
    public ResponseEntity<Map<String, Object>> slotFallback() {
        return buildFallback("slot-service", "Dịch vụ quản lý phòng khám tạm thời không khả dụng.");
    }

    @RequestMapping("/chat")
    public ResponseEntity<Map<String, Object>> chatFallback() {
        return buildFallback("chat-service", "Dịch vụ tin nhắn tạm thời không khả dụng.");
    }

    private ResponseEntity<Map<String, Object>> buildFallback(String service, String message) {
        return ResponseEntity
                .status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of(
                        "code", HttpStatus.SERVICE_UNAVAILABLE.value(),
                        "service", service,
                        "message", message,
                        "status", "CIRCUIT_OPEN"
                ));
    }
}
