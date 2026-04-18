# Plan 9: Integration Testing & E2E Verification

## Phạm vi
Comprehensive testing & verification toàn bộ appointment-service flow.

## Tasks
### 9.1 Unit Tests
- Test ExamPackageService (query, create, update)
- Test ExamPackageStepService
- Test AppointmentService validation logic
- Test Saga logic (dry run, no dependencies)
- Test RabbitMQ message serialization / deserialization
- Test gRPC client error handling (mock stubs)
- Coverage: 80%+

### 9.2 Integration Tests (Testcontainers)
#### 9.2.1 Database Integration
- Test ExamPackage/Step CRUD against real DB
- Test Appointment creation, query, update
- Test reservation tracking (AppointmentResourceReservation)

#### 9.2.2 RabbitMQ Integration
- Spin up Testcontainer RabbitMQ
- Test saga flow: publish command → consumer process → reply published
- Test cases:
  - DoctorReserve success → doctor slot marked reserved
  - DoctorReserve fail → no reservation created
  - RoomSlotReserve success → room slot marked reserved
  - EquipmentSlotReserve success
  - Cancel releases all reservations
  - Duplicate message idempotency (inbox pattern)

#### 9.2.3 gRPC Integration
- Spin up test gRPC servers (doctor, slot)
- Test appointment gRPC client calls
- Test cases:
  - Doctor found → allocation success
  - Doctor not found → 404
  - Schedule validation pass/fail
  - Room category match/mismatch
  - Equipment type validation

### 9.3 End-to-End Tests
#### 9.3.1 Test Scenario: Happy Path Booking
```
1. Admin tạo ExamPackage "General Checkup" (3 steps: vital, ultrasound, blood-test)
2. Admin tạo ExamPackageStep "Ultrasound" (requiredRoomCategory=ULTRASOUND_ROOM, equipmentRequired=true)
3. User POST /appointments
   {
     "packageId": "general-checkup",
     "packageStepId": "ultrasound",
     "doctorId": "doc-1",
     "doctorScheduleId": 101,
     "roomSlotId": 202,
     "equipmentSlotId": 303
   }
4. Appointment-service validate gRPC (doctor, schedule, room, equipment)
5. Appointment-service return 202 + appointmentId
6. Appointment-service publish DOCTOR_RESERVE → doctor-service
7. Doctor-service accept → reply success
8. Appointment-service publish ROOM_SLOT_RESERVE → slot-service
9. Slot-service accept → reply success
10. Appointment-service publish EQUIPMENT_SLOT_RESERVE → slot-service
11. Slot-service accept → reply success
12. Appointment-service mark CONFIRMED
13. User GET /appointments/{id} → status = CONFIRMED
14. Verify: doctor slot reserved, room slot reserved, equipment slot reserved
```

#### 9.3.2 Test Scenario: Booking with Validation Failure
```
1. User POST /appointments nhưng doctor không có specialty hợp lệ
2. gRPC call doctor-service → doctor specialty NEUROLOGY nhưng step chỉ allow CARDIOLOGY
3. Appointment-service reject (400)
4. No MQ messages sent
5. No reservations created
```

#### 9.3.3 Test Scenario: Cascade Failure Compensation
```
1. User POST /appointments
2. DoctorReserve success ✓
3. RoomSlotReserve fail ✗
4. Appointment-service compensate:
   - Publish DoctorRelease
   - Doctor-service release slot
5. Appointment-service mark BOOKING_FAILED
6. Verify: doctor slot available again, appointment status = BOOKING_FAILED
```

#### 9.3.4 Test Scenario: Cancel with Full Compensation
```
1. Appointment status = CONFIRMED (all reserved)
2. User POST /appointments/{id}/cancel { reason: "change mind" }
3. Appointment-service mark CANCELLATION_PENDING
4. Publish EquipmentSlotRelease
5. Slot-service release + reply success
6. Publish RoomSlotRelease
7. Slot-service release + reply success
8. Publish DoctorRelease
9. Doctor-service release + reply success
10. Appointment-service mark CANCELLED
11. Verify: all slots available again, appointment status = CANCELLED
```

### 9.4 OpenAPI Documentation Update
- Verify all endpoints documented
- Verify request/response schemas
- Verify error codes (400, 402, 403, 404, 503)
- Verify security schemes (JWT Bearer)
- Generate OpenAPI spec from code

### 9.5 Docker Compose Integration
- Start full stack: appointment, doctor, slot, RabbitMQ, Keycloak
- Verify healthchecks pass
- Run integration test suite against running containers
- Verify service-to-service communication works

### 9.6 Performance / Load Testing (Optional)
- Load test booking with concurrent users
- Measure gRPC latency
- Measure RabbitMQ throughput
- Identify bottlenecks

### 9.7 Documentation
- Update appointment-service `readme.md`
  - Architecture overview
  - Data flow diagrams
  - API documentation links
  - Running locally: `docker compose up`
  - Testing: `mvn test`, `mvn verify`
  
- Add architecture diagram (ASCII or Mermaid)
  - Appointment → Doctor (gRPC)
  - Appointment → Slot (gRPC)
  - Appointment publishes → RabbitMQ → Doctor/Slot consumers
  - Replies flow back

## Acceptance Criteria
- [ ] Unit tests: 80%+ coverage, all pass
- [ ] Integration tests: all pass (DB, RabbitMQ, gRPC)
- [ ] E2E tests: all 4 scenarios pass
  - Happy path booking
  - Validation failure
  - Cascade failure + compensation
  - Cancel with full compensation
- [ ] Docker compose: `docker compose up` start all services
- [ ] All services healthy (GET /health → 200)
- [ ] OpenAPI spec complete & accurate
- [ ] readme.md updated with architecture & examples
- [ ] No security issues (JWT validation, secret management)
- [ ] Logs clear & helpful for debugging

## Definition of "Done" for Full Appointment Service
✅ All 9 plans completed
✅ Code quality gates passed (coverage, security scan)
✅ Code review approved
✅ Deployment ready to staging
✅ Documentation complete

## Estimate
**4-6 giờ** (comprehensive testing + docker validation + documentation)

---

## Summary: Execution Order & Timeline
```
Plan 1 (Domain Model)           → 2-3 hrs ✓ Foundation
  ↓
Plan 2 (Package APIs)            → 3-4 hrs ✓ Admin features
  ↓
Plan 3 (Appointment REST API)    → 4-5 hrs ✓ Core booking
  ↓
Plan 4 (gRPC Proto)              → 1-1.5 hrs ✓ Infra setup
  ↓
Plan 5 (gRPC Client)             → 4-5 hrs ✓ Integration
  ↓
Plan 6 (gRPC Servers)            → 5-6 hrs ✓ Doctor + Slot servers
  ↓
Plan 7 (Saga + RabbitMQ)         → 6-8 hrs ✓ Async orchestration
  ↓
Plan 8 (RabbitMQ Consumers)      → 5-6 hrs ✓ Event processing
  ↓
Plan 9 (Integration + E2E Tests) → 4-6 hrs ✓ Verification

**Total Estimate: 34-44 hours** (1 week for 1 developer)

Parallel opportunities:
- Plan 5 + 6 có thể overlap (gRPC client + server dev)
- Plan 6 (doctor) + Plan 6 (slot) có thể parallel

Prerequisite: Project structure + Java 17+ + Maven + Docker setup (assumed done)
```
