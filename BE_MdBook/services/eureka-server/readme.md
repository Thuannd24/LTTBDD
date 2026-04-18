# Eureka Server (Dịch vụ Đăng ký & Phát hiện)

## Tổng quan

`eureka-server` là trung tâm điều phối (Service Registry) của kiến trúc microservices MedBook. Nó đóng vai trò như một "danh bạ điện thoại", nơi tất cả các microservices khác sẽ đăng ký địa chỉ IP và cổng của chúng khi khởi động.

- **Nhiệm vụ chính**: Quản lý danh sách các instance microservices đang hoạt động và cung cấp thông tin này cho API Gateway cũng như các dịch vụ khác để thực hiện cân bằng tải (Load Balancing).
- **Cơ chế hoạt động**: Các dịch vụ gửi "nhịp tim" (heartbeat) định kỳ để duy trì trạng thái hoạt động trên Eureka. Nếu một dịch vụ gặp sự cố, Eureka sẽ tự động gỡ bỏ nó khỏi danh sách.

## Thông tin kỹ thuật

| Thành phần        | Lựa chọn                 |
| :---------------- | :----------------------- |
| Cổng (Port)       | `8761`                   |
| Framework         | Spring Cloud Netflix Eureka Server |
| Ngôn ngữ          | Java 21                  |
| Khả năng mở rộng  | Hỗ trợ chạy nhiều cụm (Clustering) |

## Giao diện Dashboard

Sau khi khởi chạy, bạn có thể truy cập vào giao diện quản lý của Eureka tại:
👉 `http://localhost:8761`

Tại đây bạn có thể xem:
- Danh sách các dịch vụ đang trực tuyến (Up).
- Địa chỉ IP và Port của từng instance.
- Trạng thái sức khỏe (Health status) của hệ thống.

## API Endpoints

Mặc dù chủ yếu cung cấp giao diện web, Eureka cũng hỗ trợ các API REST:

| Phương thức | Đường dẫn      | Mô tả                                       |
| :---------- | :------------- | :------------------------------------------ |
| GET         | `/health`      | Kiểm tra trạng thái hoạt động (Health check)|
| GET         | `/`            | Dashboard giao diện người dùng (HTML)       |
| GET         | `/eureka/apps` | Lấy danh sách toàn bộ ứng dụng đang đăng ký |

## Khởi chạy cục bộ

```bash
# Sử dụng Docker Compose
docker compose up eureka-server --build
```

Hoặc chạy độc lập bằng Maven:
```bash
cd services/eureka-server
mvn spring-boot:run
```

## Cấu hình quan trọng

Trong file `application.yml` của các dịch vụ khác, bạn cần khai báo địa chỉ của Eureka:

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

## Cấu trúc thư mục

```text
eureka-server/
├── Dockerfile          # Cấu hình container hóa dịch vụ
├── pom.xml             # Quản lý phụ thuộc Maven
└── src/
    └── main/
        ├── java/.../   # Mã nguồn kích hoạt Eureka Server
        └── resources/
            └── application.yml # Cấu hình port 8761 và chế độ server
```

## Ghi chú

- Vì đây là Server, nên trong cấu hình `application.yml` nội bộ, `register-with-eureka` và `fetch-registry` được đặt là `false` để tránh việc server tự đăng ký với chính nó.
- Cần khởi động `eureka-server` đầu tiên trước khi chạy bất kỳ microservice nào khác.
