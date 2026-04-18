package com.medbook.slotservice.configuration;

import java.io.IOException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.slotservice.dto.ApiResponse;
import com.medbook.slotservice.exception.ErrorCode;

/**
 * Lớp cấu trúc lỗi xác thực JwtAuthenticationEntryPoint.
 * 
 * Mục đích: Đây là cái "Phễu" lọc lỗi bảo mật. Bất kì ai cố tình xâm nhập vào các đường link
 * cần đăng nhập mà KHÔNG CÓ TOKEN (hoặc token bị hết hạn, giả mạo) thì Spring Security sẽ ném ra lỗi.
 * Thay vì để Spring tát vào mặt người dùng một đống báo lỗi HTML 401 nhìn rất xấu, lớp này sẽ
 * chặn lỗi đó lại, biến nó thành định dạng JSON chuẩn của hệ thống để Frontend hiển thị popup đẹp đẽ.
 */
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

    // Phương thức commence() sẽ tự động được Spring Security kích hoạt
    // Bất cứ khi nào 1 Request bị từ chối truy cập do CHƯA ĐĂNG NHẬP (Missing hoặc Invalid Token)
    @Override
    public void commence(
            HttpServletRequest request, HttpServletResponse response, AuthenticationException authException)
            throws IOException {
        ErrorCode errorCode = ErrorCode.UNAUTHORIZED;

        // Thay vì trả về một trang báo lỗi HTML của hệ thống Spring (hoặc mã 401 đơn điệu),
        // Chúng ta ghi đè luồng xuất, đóng gói đối tượng ApiResponse và trả nó về dưới dạng JSON
        // chuẩn của dự án để Frontend dễ dàng bóc tách thông báo gốc.
        response.setStatus(401);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        ApiResponse<?> apiResponse = ApiResponse.builder()
                .code(errorCode.getCode())
                .message(errorCode.getMessage())
                .build();

        ObjectMapper objectMapper = new ObjectMapper();

        response.getWriter().write(objectMapper.writeValueAsString(apiResponse));
        response.flushBuffer();
    }
}
