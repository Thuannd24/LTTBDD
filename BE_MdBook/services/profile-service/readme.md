# Profile Service

## Overview

The `profile-service` manages user profile data for the MedBook HMS platform.

- **Business domain**: Quản lý thông tin chi tiết người dùng (bệnh nhân/user profile).
- **Data owned**: UserProfile entity (firstName, lastName, phone, avatar, dob, gender, address, etc.)
- **Operations**: Get/Update own profile, get profile by userId, internal APIs for inter-service calls.

This service does **NOT** handle login, registration, JWT issuance, or role authorization — those are handled by `identity-service`.

## Tech Stack

| Component      | Choice                   |
| :------------- | :----------------------- |
| Language       | Java 21                  |
| Framework      | Spring Boot 3.2.2        |
| Database       | PostgreSQL                |
| ORM            | Spring Data JPA / Hibernate |
| Security       | Spring Security OAuth2 Resource Server |
| Service Discovery | Eureka Client         |
| Inter-service  | OpenFeign                |
| Mapper         | MapStruct                |
| Docs           | springdoc-openapi (Swagger) |

## API Endpoints

| Method | Path                                   | Auth Required | Description                              |
| :----- | :------------------------------------- | :------------ | :--------------------------------------- |
| GET    | `/profile/users/me`                    | Yes           | Get current user's profile               |
| PUT    | `/profile/users/me`                    | Yes           | Update current user's profile            |
| GET    | `/profile/users/{userId}`              | Yes           | Get profile by userId                    |
| GET    | `/profile/internal/users/{userId}`     | No (internal) | Internal: get profile for inter-service  |
| POST   | `/profile/internal/users`              | No (internal) | Internal: create profile from identity-service |
| GET    | `/profile/internal/users/check/{userId}` | No (internal) | Internal: check if profile exists      |
| GET    | `/profile/actuator/health`             | No            | Health check                             |
| GET    | `/profile/swagger-ui.html`             | No            | Swagger UI                               |

Via API Gateway (`/api/v1/profile/**` → `profile-service`):
- `GET /api/v1/profile/users/me`
- `PUT /api/v1/profile/users/me`
- `GET /api/v1/profile/users/{userId}`

## Running Locally

```bash
# From project root
docker compose up profile-service db-profile --build
```

Or run standalone:
```bash
cd services/profile-service
mvn spring-boot:run
```

## Environment Variables

| Variable                  | Description                   | Default                                        |
| :------------------------ | :---------------------------- | :--------------------------------------------- |
| `SPRING_DATASOURCE_URL`   | JDBC URL for PostgreSQL       | `jdbc:postgresql://localhost:5432/profile_db`  |
| `SPRING_DATASOURCE_USERNAME` | DB username               | `admin`                                        |
| `SPRING_DATASOURCE_PASSWORD` | DB password               | `password`                                     |
| `EUREKA_SERVER_URL`       | Eureka discovery URL          | `http://localhost:8761/eureka`                 |

## Testing

```bash
cd services/profile-service
mvn test
```

## Project Structure

```text
profile-service/
├── Dockerfile
├── pom.xml
├── readme.md
└── src/
    └── main/
        ├── java/com/medbook/profile/
        │   ├── ProfileServiceApplication.java
        │   ├── configuration/          # Security, JWT, JPA Auditing
        │   ├── controller/             # UserProfileController, InternalUserProfileController
        │   ├── dto/
        │   │   ├── ApiResponse.java
        │   │   ├── request/            # UpdateMyProfileRequest, CreateInternalProfileRequest
        │   │   └── response/           # UserProfileResponse, InternalUserProfileResponse, ProfileExistenceResponse
        │   ├── entity/                 # UserProfile
        │   ├── exception/              # AppException, ErrorCode, GlobalExceptionHandler
        │   ├── mapper/                 # UserProfileMapper (MapStruct)
        │   ├── repository/             # UserProfileRepository
        │   └── service/               # UserProfileService, UserProfileServiceImpl
        └── resources/
            └── application.yml
```

## Notes

- Internal endpoints (`/internal/**`) are `permitAll` for inter-service communication convenience.
- **TODO (Production)**: Secure `/internal/**` with service-level tokens or mutual TLS.
- `userId` is sourced from `SecurityContextHolder.getContext().getAuthentication().getName()` (JWT subject).
- `username` and `email` fields are not updatable via profile-service; changes go through `identity-service`.

