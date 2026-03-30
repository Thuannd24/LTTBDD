# Fashion App (Flutter Frontend)

Dự án này là giao diện Front-end (FE) được xây dựng bằng Flutter cho một cửa hàng thời trang. Dự án đã được cấu hình chuẩn để kết nối với Backend (BE) thông qua các API xác thực.

## 🚀 Tính năng nổi bật
* **Giao diện Fashion cao cấp**: Hình ảnh nền chất lượng cao, hiệu ứng Gradient và bo góc tinh tế.
* **Xác thực API**: Kết nối trực tiếp tới Identity Service (Đăng nhập/Lấy thông tin người dùng).
* **Biến môi trường**: Sử dụng `.env` để quản lý URL API linh hoạt.
* **Cấu trúc Feature-based**: Dễ dàng mở rộng và bảo trì.

---

## 🛠 Hướng dẫn chạy dự án

### 1. Chuẩn bị
* Flutter SDK (>= 3.10.0)
* Android Studio hoặc VS Code
* Backend (Identity Service) đang chạy tại cổng `8080`

### 2. Cấu hình biến môi trường
1. Copy file mẫu `.env_example` và đổi tên thành `.env`:
   ```bash
   cp .env_example .env
   ```
2. Mở file `.env` và cập nhật `API_URL` của bạn (nếu cần).

### 3. Cài đặt thư viện
```bash
flutter pub get
```

### 4. Kết nối thiết bị thực qua cáp USB
Nếu bạn sử dụng điện thoại thật (như Redmi, Samsung...) qua dây cáp, hãy chạy lệnh sau để thiết bị có thể thấy được Backend trên máy tính của bạn:
```bash
adb reverse tcp:8080 tcp:8080
```

### 5. Chạy ứng dụng
```bash
flutter run
```

---

## 📁 Cấu trúc thư mục (Features)
* `lib/features/auth`: Chứa toàn bộ logic và UI về Đăng nhập & Đăng ký.
* `lib/core`: Chứa cấu hình mạng, hằng số và Theme.
* `lib/data`: Lớp gọi API (Services).

## 👤 Tác giả
* **Tên:** [Tên của bạn]
* **GitHub:** [https://github.com/Thuannd24](https://github.com/Thuannd24)
