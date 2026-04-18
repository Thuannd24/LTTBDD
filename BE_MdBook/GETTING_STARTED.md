# Hướng Dẫn Bắt Đầu (Getting Started) - Dự án MedBook

Tài liệu này hướng dẫn cách cài đặt, chạy thử và phát triển dự án MedBook.

---

## 1. Yêu cầu Tiền quyết (Prerequisites)

- [Docker Desktop](https://docs.docker.com/get-docker/) (Đã bao gồm Docker Compose)
- [Git](https://git-scm.com/)

*(Lưu ý: Bạn không cần cài đặt Java hay Maven trên máy thật vì hệ thống sử dụng Docker Multistage Build).*

---

## 2. Khởi chạy Nhanh (Quick Start)

```bash
# 1. Clone dự án
git clone https://github.com/thuan2412004/microservices-assignment-starter.git
cd microservices-assignment-starter

# 2. Khởi tạo môi trường (.env)
cp .env.example .env
# Mở file .env và điền các thông tin nhạy cảm (Email, Keycloak Secret)

# 3. Chạy toàn bộ hệ thống bằng Docker Compose
docker compose up --build -d
```

### Kiểm tra các cổng dịch vụ:
*   **API Gateway**: `http://localhost:8080` (Cổng chính)
*   **Health Check**: `http://localhost:8080/health`
*   **Eureka Server**: `http://localhost:8761` (Xem các service online)
*   **Keycloak**: `http://localhost:8181`

---

## 3. Quy trình Phát triển (Workflow)

1.  **Sửa Code**: Thực hiện thay đổi tại thư mục `services/` hoặc `frontend/`.
2.  **Cập nhật cấu hình**: Sửa file `.env` nếu cần thiết.
3.  **Deploy lại**: Chạy lệnh `docker compose up --build <service-name>` để Docker tự động rebuild và cập nhật service đó.

---

## 4. Checklist Trước khi Nộp bài (Submission)

- [ ] `README.md` đầy đủ thông tin nhóm.
- [ ] File `.env.example` chứa các biến mẫu sạch sẽ.
- [ ] Luồng Saga hoạt động (Kiểm tra qua Postman & Email).
- [ ] Mọi service đều trả về `{"status": "ok"}` tại `/health`.
