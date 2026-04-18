# Plan 1: Tạo Domain Model & JPA Entities

## Phạm vi
Tạo toàn bộ entity classes cho appointment-service domain.

## Tasks
### 1.1 Tạo ExamPackage entity
- Entity: `ExamPackage`
- Fields: id, code, name, description, status, estimatedTotalMinutes, createdAt, updatedAt
- Repository: `ExamPackageRepository`
- Test: Validate entity mapping

### 1.2 Tạo ExamPackageStep entity
- Entity: `ExamPackageStep`
- Fields: id, packageId (FK), stepOrder, stepName, allowedSpecialtyIds (JSON), requiredRoomCategory, requiredEquipmentType, equipmentRequired (boolean), estimatedMinutes, note
- Repository: `ExamPackageStepRepository`
- Relationship: @ManyToOne với ExamPackage

### 1.3 Tạo Appointment entity
- Entity: `Appointment`
- Fields: id, sagaId, patientUserId, doctorId, doctorScheduleId, facilityId, packageId, packageStepId, status (enum), note, cancelReason, failureCode, failureMessage, createdAt, updatedAt
- Status enum: BOOKING_PENDING, CONFIRMED, BOOKING_FAILED, CANCELLATION_PENDING, CANCELLED, CANCELLATION_FAILED
- Repository: `AppointmentRepository`

### 1.4 Tạo AppointmentResourceReservation entity
- Entity: `AppointmentResourceReservation`
- Fields: id, appointmentId (FK), slotId, targetType (DOCTOR/ROOM/EQUIPMENT), targetId, status
- Repository: `AppointmentResourceReservationRepository`

### 1.5 Tạo AppointmentPackageContext entity
- Entity: `AppointmentPackageContext`
- Fields: id, appointmentId (FK), packageStepId, validationContext (JSON - lưu thông tin validate)
- Repository: `AppointmentPackageContextRepository`

### 1.6 Tạo Saga & Outbox/Inbox entities
- Entity: `AppointmentSaga`
  - Fields: id, appointmentId (FK), sagaId, status, compensationIndex
- Entity: `OutboxEvent`
  - Fields: id, aggregateId, eventType, payload (JSON), published (boolean), createdAt
- Entity: `InboxMessage`
  - Fields: id, messageId, eventType, payload (JSON), processed (boolean), createdAt

## Acceptance Criteria
- [ ] Tất cả 7 entities được tạo với đầy đủ fields
- [ ] Relationships (@OneToMany, @ManyToOne, @FK) chính xác
- [ ] Repositories được sinh tự động bởi Spring Data JPA
- [ ] Database schema hợp lệ (có thể start service)
- [ ] Unit tests verify entity mapping

## Estimate
**2-3 giờ** (tạo entities, test, verify schema)
