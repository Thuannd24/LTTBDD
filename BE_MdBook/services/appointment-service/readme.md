# Appointment Service

`appointment-service` là orchestration service cho booking lifecycle. Nó không sở hữu doctor schedule hay resource slot; nó điều phối hai service đó.

## Current target architecture

- `doctor-service`: reserve/release `DoctorSchedule`
- `slot-service`: reserve/release resource slot
- `appointment-service`: persist appointment, điều phối reserve/release, publish notification

## Planned API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/appointment/appointments/health` | Health check |
| `POST` | `/api/v1/appointment/appointments` | Tạo appointment |
| `GET` | `/api/v1/appointment/appointments/{id}` | Xem chi tiết appointment |
| `GET` | `/api/v1/appointment/appointments/my` | Xem appointment của tôi |
| `GET` | `/api/v1/appointment/appointments/doctor/{doctorId}` | Xem appointment theo doctor |
| `POST` | `/api/v1/appointment/appointments/{id}/cancel` | Hủy appointment |
| `POST` | `/api/v1/appointment/appointments/{id}/check-in` | Check-in |

## Booking contract draft

Request đề xuất:

```json
{
  "doctorScheduleId": 123,
  "resourceSlotId": 456,
  "note": "Follow-up visit"
}
```

## Current status

- service chưa được implement
- design chi tiết đã được cập nhật trong `services/appointment-service/plan.md`
- gateway canonical path đã được đồng bộ về `/api/v1/appointment/**`

## Running locally

```bash
docker compose up appointment-service --build
```

## Environment variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_DATASOURCE_URL` | JDBC URL | `jdbc:postgresql://localhost:5432/appointment_db` |
| `SPRING_RABBIT_HOST` | RabbitMQ host | `localhost` |
| `EUREKA_SERVER_URL` | Eureka URL | `http://localhost:8761/eureka` |

## Testing

```bash
mvn test
```
