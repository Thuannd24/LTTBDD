# Slot-Service

`slot-service` quản lý availability của tài nguyên vật lý trong hệ thống MedBook. Sau refactor, service này không còn đại diện cho lịch làm việc của bác sĩ.

## Thông tin cơ bản

| Thông tin | Giá trị |
|-----------|---------|
| Port | `5011` |
| Context path | `/slot` |
| Database | PostgreSQL (`slot_db`) |
| Cache | Redis |
| Spring app name | `slot-service` |

## Domain boundary

Service này sở hữu:

- `resourceId`
- `resourceType`
- `facilityId`
- `startTime`
- `endTime`
- `status`
- `appointmentId`

`resourceType` hiện hỗ trợ:

- `ROOM`
- `EQUIPMENT`
- `FACILITY_UNIT`

## API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/slot/slots/health` | Health check |
| `GET` | `/slot/slots/available` | Query resource slots có sẵn |
| `POST` | `/slot/slots/recurring` | Tạo recurring config cho resource |
| `GET` | `/slot/slots/recurring/resource/{resourceId}` | Xem recurring config theo resource |
| `POST` | `/slot/slots/{slotId}/reserve` | Reserve slot cho appointment |
| `POST` | `/slot/slots/{slotId}/book` | Alias tương thích ngược, tương đương `reserve` |
| `POST` | `/slot/slots/{slotId}/release` | Release slot |
| `POST` | `/slot/slots/{slotId}/block` | Block slot |
| `GET` | `/slot/slots/{slotId}/history` | Xem lịch sử slot |

Qua gateway:

- `http://localhost:8080/api/v1/slot/slots/...`

## Availability query

`GET /slot/slots/available`

Query params:

- `facilityId`
- `resourceType`
- `date`
- optional `resourceId`
- optional `limit`

Ví dụ:

```bash
curl "http://localhost:8080/api/v1/slot/slots/available?facilityId=2&resourceType=ROOM&resourceId=room-1&date=2026-04-15" \
  -H "Authorization: Bearer <token>"
```

## Recurring config

Ví dụ tạo recurring config:

```bash
curl -X POST "http://localhost:8080/api/v1/slot/slots/recurring" \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"resourceId":"room-1","resourceType":"ROOM","facilityId":2,"dayOfWeek":"MONDAY","startTime":"09:00","endTime":"17:00","slotDurationMinutes":30}'
```

## Appointment contract

Contract mới để `appointment-service` dùng:

```http
POST /slot/slots/{slotId}/reserve
Content-Type: application/json

{
  "appointmentId": 42
}
```

Release:

```http
POST /slot/slots/{slotId}/release
```

`/book` chỉ còn là alias tương thích ngược.

## Run

```bash
cd services/slot-service
mvn spring-boot:run
```

## Test

```bash
mvn test
```
