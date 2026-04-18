# Identity-Service

`identity-service` là trung tâm quản lý định danh (IAM) cho MedBook, chịu trách nhiệm đăng ký người dùng và tích hợp với Keycloak.

## Thông tin cơ bản

| Thông tin | Giá trị |
|-----------|---------|
| Port | `5001` |
| Context path | `/identity` |
| Security | Keycloak Admin API, OAuth2 |
| Spring app name | `identity-service` |

## Domain boundary

Service này không sở hữu database người dùng riêng mà thao tác trực tiếp trên Keycloak:
- **Registration**: Tạo user trên Keycloak và đồng bộ sang `profile-service` qua Feign client.
- **Authentication**: Không trực tiếp xử lý login (login được thực hiện tại Keycloak), nhưng cung cấp thông tin Token và User info.
- **Roles**: Quản lý các nhóm quyền `ADMIN`, `DOCTOR`, `PATIENT`.

## API

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/identity/users/registration` | Đăng ký tài khoản mới |
| `GET`  | `/identity/users/my-info` | Lấy thông tin user dựa trên Token |
| `GET`  | `/identity/users` | (Admin) Lấy danh sách user từ Keycloak |
| `DELETE` | `/identity/users/{userId}` | (Admin) Xóa user và tài khoản Keycloak |

## Project Structure

```text
identity-service/
├── Dockerfile
├── pom.xml
└── src/
    └── main/
        ├── java/com/identityservice/
        │   ├── configuration/          # Cấu hình Security, Keycloak Client
        │   ├── controller/             # UserController, HealthCheckController
        │   ├── dto/                    # Request/Response cho User & Profile sync
        │   ├── exception/              # GlobalExceptionHandler
        │   ├── mapper/                 # MapStruct
        │   └── service/                # Logic gọi Keycloak Admin API
        └── resources/
            └── application.yaml
```

## Running Locally

```bash
cd services/identity-service
mvn spring-boot:run
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `KEYCLOAK_SERVER_URL` | URL của máy chủ Keycloak | `http://keycloak:8080` |
| `KEYCLOAK_ADMIN_CLIENT_SECRET` | Secret của admin-cli | (Lấy từ .env) |
