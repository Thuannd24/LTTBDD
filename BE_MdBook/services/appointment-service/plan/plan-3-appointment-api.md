# Plan 3: Public API - Appointment Booking (REST)

## Phạm vi
Triển khai appointment booking REST API (V1 = 1 step chỉ).

## Tasks
### 3.1 Tạo AppointmentController
- Endpoint: `POST /appointments` (authenticated)
  - Tạo appointment booking mới
  - Request: `CreateAppointmentRequest`
  - Response: `202 Accepted` + `CreateAppointmentResponse` wrapped in `ApiResponse<CreateAppointmentResponse>(appointmentId, sagaId, status=BOOKING_PENDING)
  - Logic:
    - Extract JWT từ header (tạm thời forward xuống gRPC)
    - Validate request (packageId, packageStepId, doctorId, etc. không null)
    - Trigger saga booking workflow (asynchronous)
    - Return ngay với 202

- Endpoint: `GET /appointments/{id}` (authenticated)
  - Lấy thông tin appointment
  - Response: `ApiResponse<AppointmentResponse>`
  - Validate: user có quyền xem appointment này không (owner hoặc ADMIN)

- Endpoint: `GET /appointments/{id}/status` (authenticated)
  - Lấy status appointment (polling)
  - Response: `ApiResponse<AppointmentStatusResponse>` { status, failureCode }

- Endpoint: `GET /appointments/my` (authenticated)
  - Lấy danh sách appointments của user hiện tại (pagination)
  - Response: `ApiResponse<Page<AppointmentResponse>>`

- Endpoint: `GET /appointments/doctor/{doctorId}` (ADMIN + DOCTOR)
  - Lấy danh sách appointments của doctor
  - Response: `ApiResponse<Page<AppointmentResponse>>`

- Endpoint: `POST /appointments/{id}/cancel` (authenticated)
  - Hủy appointment
  - Request: `CancelAppointmentRequest` { reason }
  - Response: `ApiResponse<AppointmentResponse>` (status=CANCELLATION_PENDING)
  - Trigger cancel saga workflow (asynchronous)

### 3.2 Tạo AppointmentService (request handler)
- `createAppointment(CreateAppointmentRequest, JWT token)` → CreateAppointmentResponse (appointmentId, sagaId, status)
- `getAppointment(appointmentId)` → AppointmentResponse
- `getMyAppointments(userId, pageable)` → Page<AppointmentResponse>
- `getDoctorAppointments(doctorId, pageable)` → Page<AppointmentResponse>
- `getAppointmentStatus(appointmentId)` → AppointmentStatusResponse (status, failureCode)
- `cancelAppointment(appointmentId, reason, JWT)` → AppointmentResponse (status=CANCELLATION_PENDING)

### 3.3 Tạo DTOs
Follow naming convention: use **Request** for mutations, **Response/DTO** for queries

**Request DTOs:**
- `CreateAppointmentRequest` (POST /appointments):
  ```json
  {
    "packageId": "pkg-general-checkup",
    "packageStepId": "step-ultrasound",
    "doctorId": "doctor-123",
    "doctorScheduleId": 101,
    "roomSlotId": 202,
    "equipmentSlotId": 303,
    "note": "Follow-up visit"
  }
  ```
- `CancelAppointmentRequest` (POST /appointments/{id}/cancel): { reason }

**Response DTOs:**
- `AppointmentResponse` (GET /appointments/{id}): full appointment details + timestamps
- `AppointmentStatusResponse` (GET /appointments/{id}/status): { status, failureCode }
- `CreateAppointmentResponse` (POST /appointments 202): { appointmentId, sagaId, status=BOOKING_PENDING }

### 3.4 Tạo Validators
- `@ValidAppointmentRequest` - validate request structure
- Service-level validators:
  - Package exists?
  - Step exists trong package?
  - packageStepId thuộc packageId?
  - doctorId, scheduleId, roomSlotId, equipmentSlotId không null

### 3.5 Add Security/Auth
- POST /appointments: @PreAuthorize("isAuthenticated()")
- GET /appointments/my: @PreAuthorize("isAuthenticated()")
- GET /appointments/{id}: @PreAuthorize("isAuthenticated() AND (isSelf(#id) OR hasRole('ADMIN'))")
- GET /appointments/doctor/{doctorId}: @PreAuthorize("hasRole('ADMIN') OR isDoctorOrStaff()")
- POST /appointments/{id}/cancel: @PreAuthorize("isAuthenticated() AND isSelf(#id)")

## Acceptance Criteria
- [ ] POST /appointments trả 202 + appointmentId (async)
- [ ] GET /appointments/{id} trả appointment details
- [ ] GET /appointments/my trả danh sách user's appointments
- [ ] GET /appointments/{id}/status polling hoạt động
- [ ] GET /appointments/doctor/{doctorId} (ADMIN + DOCTOR only)
- [ ] POST /appointments/{id}/cancel trigger async cancel
- [ ] AuthN/AuthZ verify chính xác
- [ ] Unit tests cho services (validation, mutation)
- [ ] Integration tests cho controllers + security
- [ ] OpenAPI spec cập nhật
- [ ] Lệnh `docker compose up` vẫn hoạt động (no gRPC yet)

## Notes
- **Chưa implement gRPC validation** - chỉ basic validation ở đây
- **Chưa implement saga** - chỉ create appointment + sync trigger
- **gRPC integration sẽ ở plan tiếp theo**

## Estimate
**4-5 giờ** (controllers, services, DTOs, validators, tests, OpenAPI, security)
