# API Gateway

## Tổng quan

`gateway-service` đóng vai trò là điểm vào duy nhất (Single Entry Point) cho toàn bộ hệ thống microservices của MedBook. Nó chịu trách nhiệm điều phối các yêu cầu từ phía Client (Frontend, Mobile) đến các dịch vụ nội bộ tương ứng.

## Chức năng chính

1.  **Định tuyến (Routing)**: Chuyển tiếp các yêu cầu dựa trên tiền tố đường dẫn (Path Prefix).
2.  **Cân bằng tải (Load Balancing)**: Sử dụng Spring Cloud LoadBalancer để phân phối yêu cầu đến các instance dịch vụ được đăng ký trên Eureka (thông qua giao thức `lb://`).
3.  **Xử lý CORS**: Cấu hình chia sẻ tài nguyên giữa các nguồn khác nhau, cho phép Frontend giao tiếp với Backend mà không bị chặn bởi trình duyệt.
4.  **Hỗ trợ WebSocket**: Định tuyến các kết nối Socket.IO cho dịch vụ Chat.
5.  **Chống lỗi dây chuyền (Circuit Breaker)**: Sử dụng **Resilience4j** để tự động ngắt kết nối và trả về phản hồi thay thế khi một dịch vụ nội bộ bị lỗi hoặc quá tải.

## Danh mục định tuyến (Route Table)

Tất cả các API được tiếp nhận tại cổng **8080**.

| Dịch vụ             | Gateway Path Prefix      | Backend Service ID | Ghi chú                                   |
| :------------------ | :----------------------- | :----------------- | :---------------------------------------- |
| **Authentication**  | `/api/v1/auth/**`        | Keycloak (External)| Trỏ trực tiếp đến OpenID Connect của Keycloak |
| **Identity Service**| `/api/v1/identity/**`    | `IDENTITY-SERVICE` | Quản lý User, Đăng ký                     |
| **Profile Service** | `/api/v1/profile/**`     | `PROFILE-SERVICE`  | Quản lý hồ sơ người dùng                  |
| **Doctor Service**  | `/api/v1/doctor/**`      | `DOCTOR-SERVICE`   | Danh mục bác sĩ & Chuyên khoa             |
| **Specialty API**   | `/api/v1/specialty/**`   | `DOCTOR-SERVICE`   | Alias cho các tài nguyên chuyên khoa      |
| **Appointment Svc** | `/api/v1/appointment/**` | `APPOINTMENT-SERVICE`| Điều phối đặt lịch (Saga)                |
| **Slot Service**    | `/api/v1/slot/**`        | `SLOT-SERVICE`     | Quản lý tài nguyên vật lý (Phòng/Máy)     |
| **Chat Service**    | `/api/v1/chat/**`        | `chat-service`     | Hỗ trợ WebSocket / Socket.IO              |

## Xử lý sự cố (Fallback Mechanisms)

Khi một dịch vụ nội bộ gặp sự cố, Gateway sẽ kích hoạt Circuit Breaker và chuyển tiếp yêu cầu đến các endpoint fallback nội bộ:

| Service Failure    | Fallback Path             | Response                                  |
| :----------------- | :------------------------ | :---------------------------------------- |
| `IDENTITY-SERVICE` | `/fallback/identity`      | 503 SERVICE_UNAVAILABLE + Thông báo lỗi    |
| `PROFILE-SERVICE`  | `/fallback/profile`       | 503 SERVICE_UNAVAILABLE + Thông báo lỗi    |
| `DOCTOR-SERVICE`   | `/fallback/doctor`        | 503 SERVICE_UNAVAILABLE + Thông báo lỗi    |
| `APPOINTMENT-SVC`  | `/fallback/appointment`   | 503 SERVICE_UNAVAILABLE + Thông báo lỗi    |
| `SLOT-SERVICE`     | `/fallback/slot`          | 503 SERVICE_UNAVAILABLE + Thông báo lỗi    |
| `CHAT-SERVICE`     | `/fallback/chat`          | 503 SERVICE_UNAVAILABLE + Thông báo lỗi    |

## Công nghệ sử dụng

- **Java 21** & **Spring Boot 3.x**
- **Spring Cloud Gateway**: Framework chính xử lý reactive gateway.
- **Eureka Client**: Đăng ký và phát hiện dịch vụ tự động.
- **Netty**: Server engine hiệu năng cao cho các kết nối không đồng bộ.
- **Resilience4j**: Thư viện xử lý Fault Tolerance (Circuit Breaker, Rate Limiter).

## Cấu hình CORS

Hiện tại, Gateway đang được cấu hình cho phép tất cả các nguồn (`allowedOrigins: "*"`) để thuận tiện cho quá trình phát triển (Development). Trong môi trường Production, cần giới hạn danh sách Domain của Frontend.

## Khởi chạy cục bộ

```bash
# Đảm bảo Eureka Server đã chạy trước
docker compose up gateway-service --build
```

API sẽ khả dụng tại: `http://localhost:8080/api/v1/...`

## Ghi chú quan trọng

- **Mật khẩu & Token**: Client nên gửi các yêu cầu đăng nhập trực tiếp qua `/api/v1/auth/token`. Gateway sẽ tự động chuyển tiếp đến Keycloak để xử lý.
- **Phân tách Frontend/Backend**: Mọi giao tiếp từ Frontend đều nên đi qua Gateway thay vì gọi trực tiếp đến port của từng microservice để đảm bảo tính bảo mật và dễ quản lý.
