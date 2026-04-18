# Plan 5: gRPC Client Integration (Appointment → Doctor/Slot)

## Phạm vi
Appointment-service gọi doctor-service và slot-service qua gRPC.

## Tasks
### 5.1 Tạo gRPC Channel & Stub Configuration
- Class: `GrpcClientConfiguration`
  - Resolve instance từ Eureka (DiscoveryClient)
  - Tạo `ManagedChannel` động theo instance được chọn (round-robin)
  - Lấy gRPC port từ Eureka metadata (fallback default port)
  - Add shutdown hook để close channels

### 5.2 Tạo gRPC Client Interceptors
- Class: `AuthenticationInterceptor`
  - Extract JWT từ ThreadLocal (set bởi request)
  - Add JWT vào gRPC metadata header (`authorization: Bearer {token}`)
  - Log gRPC calls

- Class: `ErrorHandlingInterceptor`
  - Catch gRPC errors
  - Convert `io.grpc.StatusRuntimeException` → `AppointmentServiceException`

### 5.3 Implement Doctor gRPC Client
- Class: `DoctorGrpcClient` (or `DoctorServiceGrpcClient`)
  - Method: `getDoctorById(String doctorId)` → call gRPC GetDoctorById
  - Method: `getDoctorScheduleById(String scheduleId, String doctorId)` → call gRPC GetDoctorScheduleById
  - Handle gRPC errors (not found, permission denied, timeout)
  - Return domain objects (e.g., `DoctorInfo`, `DoctorScheduleInfo`)

### 5.4 Implement Slot gRPC Client
- Class: `SlotGrpcClient` (or `SlotServiceGrpcClient`)
  - Method: `getSlotById(String slotId)` → call gRPC GetSlotById
  - Method: `getRoomById(String roomId)` → call gRPC GetRoomById
  - Method: `getEquipmentById(String equipmentId)` → call gRPC GetEquipmentById
  - Handle gRPC errors
  - Return domain objects (e.g., `SlotInfo`, `RoomInfo`, `EquipmentInfo`)

### 5.5 Integrate gRPC Calls vào Appointment Validation
- Update `AppointmentService.createAppointment()`:
  - Call `DoctorGrpcClient.getDoctorById()` → validate doctor exists
  - Call `DoctorGrpcClient.getDoctorScheduleById()` → validate schedule
  - Extract specialty từ doctor gRPC response → validate thuộc allowedSpecialtyIds
  - Call `SlotGrpcClient.getRoomById()` → validate room category
  - Call `SlotGrpcClient.getEquipmentById()` (nếu required) → validate equipment type
  - Ngừng (throw exception) nếu có validation fail

### 5.6 Add gRPC Exception Handling
- Custom exceptions:
  - `DoctorNotFoundException`
  - `DoctorScheduleNotFoundException`
  - `RoomNotFoundException`
  - `EquipmentNotFoundException`
  - `GrpcCommunicationException` (timeout, network error)

- Exception translators → REST API errors (400, 404, 503)

### 5.7 Add Configuration & Environment Variables
- `DOCTOR_SERVICE_ID`: service id trên Eureka (default: doctor-service)
- `SLOT_SERVICE_ID`: service id trên Eureka (default: slot-service)
- `GRPC_METADATA_PORT_KEY`: metadata key chứa grpc port (default: grpc.port)
- `DOCTOR_DEFAULT_GRPC_PORT`: fallback port nếu metadata chưa có (default: 50051)
- `SLOT_DEFAULT_GRPC_PORT`: fallback port nếu metadata chưa có (default: 50052)
- `GRPC_CALL_TIMEOUT_SECONDS`: timeout (default: 5)

### 5.8 Add Tests
- Unit tests cho gRPC clients (mock gRPC stubs)
- Integration tests cho AppointmentService + gRPC validation
- Test cases:
  - Doctor exists & valid
  - Doctor not found → 404
  - Schedule not found → 400
  - Specialty mismatch → 400
  - Room category mismatch → 400
  - Equipment type mismatch → 400
  - gRPC timeout → 503
  - gRPC permission denied → 403

## Acceptance Criteria
- [ ] gRPC channels configured + auto-close
- [ ] Interceptors add JWT + error handling
- [ ] DoctorGrpcClient fully functional
- [ ] SlotGrpcClient fully functional
- [ ] Appointment validation calls gRPC (doctor, schedule, room, equipment)
- [ ] Custom exceptions + REST error translation
- [ ] Unit + integration tests pass
- [ ] Environment config complete
- [ ] docker-compose.yml có DOCTOR_SERVICE_ID, SLOT_SERVICE_ID và metadata grpc port

## Notes
- gRPC servers ở doctor-service/slot-service chưa implement (plan 6)
- **Tạm thời** forward user JWT từ request header

## Estimate
**4-5 giờ** (gRPC setup, clients, integration, tests, config)
