# MedBook Backend

Backend hiện tại đã được giản lược để phục vụ demo và tích hợp FE:

- `gateway`, `eureka-server`, `identity-service`, `profile-service`
- `doctor-service`, `slot-service`, `appointment-service`
- `chat-service`

## Kiến trúc hiện tại

- Luồng đặt lịch là synchronous.
- `appointment-service` gọi trực tiếp `doctor-service` và `slot-service` qua REST/Feign.
- Đã bỏ toàn bộ lớp orchestration/message transport cũ.
- `chat-service` dùng MongoDB + Socket.IO, offline notification chỉ log nội bộ.

## Hạ tầng chính

- Postgres cho các Spring services
- MongoDB cho `chat-service`
- Redis cho `slot-service`
- Keycloak cho xác thực

## Chạy nhanh

```bash
docker compose up --build -d
```

## Ghi chú

- `appointment-service` xác nhận hoặc thất bại booking ngay trong request.
- `cancel appointment` cũng release tài nguyên ngay trong request.
