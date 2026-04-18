# Plan 6: gRPC Servers (Doctor-Service & Slot-Service)

## Phạm vi
Doctor-service và slot-service implement gRPC servers để appointment-service gọi.

## Plan 6a: Doctor-Service gRPC Server

### Tasks
#### 6a.1 Add gRPC Dependencies to doctor-service
- `io.grpc:grpc-netty-shaded`
- `io.grpc:grpc-protobuf`
- `io.grpc:grpc-stub`
- `com.google.protobuf:protobuf-java`
- Protobuf Maven plugin

#### 6a.2 Tạo DoctorServiceGrpcImpl
- Class: `DoctorServiceImpl` implements `DoctorServiceGrpc.DoctorServiceImplBase`
- Method: `getDoctorById(GetDoctorByIdRequest, StreamObserver)` 
  - Query doctor từ DB
  - Return DoctorResponse (id, name, specialty, allowedSpecialtyIds)
  - Throw NOT_FOUND nếu không tìm thấy
  
- Method: `getDoctorScheduleById(GetDoctorScheduleByIdRequest, StreamObserver)`
  - Query schedule từ DB
  - Verify schedule thuộc doctor
  - Return DoctorScheduleResponse
  - Throw NOT_FOUND hoặc INVALID_ARGUMENT

#### 6a.3 Tạo gRPC Server Configuration
- Class: `GrpcServerConfiguration`
  - Tạo `io.grpc.Server` với port từ env
  - Register DoctorServiceImpl
  - Add JWT interceptor để xác thực request
  - Start server on startup, graceful shutdown

#### 6a.4 Add gRPC Interceptor (JWT Auth)
- Class: `JwtAuthenticationInterceptor` extends `ServerInterceptor`
  - Extract JWT từ metadata header
  - Validate JWT với Keycloak (hoặc local check)
  - Allow internal calls từ appointment-service
  - Throw UNAUTHENTICATED/PERMISSION_DENIED nếu fail

#### 6a.5 Add Configuration
- `GRPC_SERVER_PORT`: port (default: 50051)
- `GRPC_ENABLE_KEEP_ALIVE`: true
- Update docker-compose.yml expose port 50051

#### 6a.6 Add Tests
- Unit tests cho gRPC service
- Test cases: doctor found, not found, schedule invalid, auth fail

---

## Plan 6b: Slot-Service gRPC Server

### Tasks
#### 6b.1 Add gRPC Dependencies to slot-service
- Same như doctor-service

#### 6b.2 Tạo SlotServiceGrpcImpl
- Class: `SlotServiceImpl` implements `SlotServiceGrpc.SlotServiceImplBase`
- Method: `getSlotById(GetSlotByIdRequest, StreamObserver)`
  - Query slot từ DB
  - Return SlotResponse (id, targetType, targetId, date, time, available)
  - Throw NOT_FOUND

- Method: `getRoomById(GetRoomByIdRequest, StreamObserver)`
  - Query room từ DB
  - Return RoomResponse (id, name, category, active)
  - Throw NOT_FOUND

- Method: `getEquipmentById(GetEquipmentByIdRequest, StreamObserver)`
  - Query equipment từ DB
  - Return EquipmentResponse (id, name, type, active)
  - Throw NOT_FOUND

#### 6b.3 Tạo gRPC Server Configuration
- Tương tự doctor-service
- Port: 50052

#### 6b.4 Add gRPC Interceptor (JWT Auth)
- Tương tự doctor-service

#### 6b.5 Add Configuration
- `GRPC_SERVER_PORT`: port (default: 50052)

#### 6b.6 Add Tests
- Unit tests cho gRPC service
- Test cases: slot found, room found, equipment found, not found, auth fail

---

## Acceptance Criteria
- [ ] Doctor-service gRPC server start thành công (port 50051)
- [ ] Slot-service gRPC server start thành công (port 50052)
- [ ] DoctorServiceImpl fully implemented
- [ ] SlotServiceImpl fully implemented
- [ ] JWT interceptor verify authorized
- [ ] Unit tests pass
- [ ] Integration tests: appointment gRPC client → doctor/slot gRPC server
- [ ] Error handling: NOT_FOUND, PERMISSION_DENIED, etc.
- [ ] docker-compose.yml configs đầy đủ
- [ ] Logs gRPC calls, auth, errors

## Estimate
**5-6 giờ** (gRPC servers, interceptor, config, tests)
