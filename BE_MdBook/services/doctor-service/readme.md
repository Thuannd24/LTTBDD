# Doctor Service

`doctor-service` hiện sở hữu:

- doctor professional profile
- doctor schedule lifecycle (`DoctorSchedule`)

Service này là source of truth cho việc bác sĩ có lịch làm việc hay không tại một thời điểm.

## Tech stack

| Component | Choice |
|-----------|--------|
| Language | Java 21 |
| Framework | Spring Boot 3.2.2 |
| Database | PostgreSQL |

## API

### Doctor catalog

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/doctor/doctors` | Lấy danh sách bác sĩ |
| `GET` | `/api/v1/doctor/doctors/{id}` | Xem chi tiết bác sĩ |
| `PUT` | `/api/v1/doctor/doctors/{id}` | Cập nhật bác sĩ |
| `DELETE` | `/api/v1/doctor/doctors/{id}` | Xóa bác sĩ |

### Doctor schedules

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/doctor/doctors/{doctorId}/schedules` | Tạo schedule |
| `GET` | `/api/v1/doctor/doctors/{doctorId}/schedules` | Xem toàn bộ schedule |
| `GET` | `/api/v1/doctor/doctors/{doctorId}/schedules/available?date=yyyy-MM-dd&facilityId=` | Xem schedule `AVAILABLE` theo ngày |
| `GET` | `/api/v1/doctor/doctor-schedules/{scheduleId}` | Xem chi tiết schedule |
| `PUT` | `/api/v1/doctor/doctor-schedules/{scheduleId}` | Cập nhật schedule |
| `DELETE` | `/api/v1/doctor/doctor-schedules/{scheduleId}` | Xóa schedule |
| `POST` | `/api/v1/doctor/doctor-schedules/{scheduleId}/reserve` | Reserve schedule cho appointment |
| `POST` | `/api/v1/doctor/doctor-schedules/{scheduleId}/release` | Release schedule |
| `POST` | `/api/v1/doctor/doctor-schedules/{scheduleId}/block` | Block schedule |

## Rules

- không cho tạo/update schedule bị chồng giờ cho cùng doctor
- `reserve` chỉ cho `AVAILABLE`
- `release` chỉ cho `RESERVED`
- schedule đang `RESERVED` không được update, delete hoặc block

## Running locally

```bash
docker compose up doctor-service --build
```

## Environment variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_DATASOURCE_URL` | JDBC URL | `jdbc:postgresql://localhost:5432/doctor_db` |
| `SPRING_DATASOURCE_USERNAME` | Database username | `admin` |
| `SPRING_DATASOURCE_PASSWORD` | Database password | `password` |
| `EUREKA_SERVER_URL` | Eureka URL | `http://localhost:8761/eureka` |

## Testing

```bash
mvn test
```
