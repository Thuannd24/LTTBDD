# Plan 7: Appointment-Service Saga Orchestrator + RabbitMQ

## Summary
Triển khai phần `appointment-service` của async saga orchestration:
- tạo saga state trong DB
- tạo outbox commands/events
- publish ra RabbitMQ
- nhận reply messages với inbox idempotency
- cập nhật `Appointment`, `AppointmentSaga`, `AppointmentResourceReservation`

Plan 7 **không** implement consumer ở `doctor-service` và `slot-service`. Phần đó thuộc plan 8.

## Scope
### Included
- RabbitMQ topology cho command/reply
- booking saga orchestrator trong `appointment-service`
- cancel saga orchestrator trong `appointment-service`
- outbox publisher polling unpublished events
- reply listener + inbox idempotency
- publish domain events `APPOINTMENT_BOOKED`, `APPOINTMENT_CANCELLED`
- unit test cho booking/cancel saga

### Excluded
- downstream RabbitMQ consumers
- downstream reply producers
- full end-to-end cross-service booking qua MQ
- forward JWT qua RabbitMQ

## Auth Model
- User JWT chỉ dùng cho HTTP và sync gRPC validation ở đầu flow.
- RabbitMQ dùng **broker authentication** giữa service và broker.
- MQ message **không** mang bearer token của user.
- Nếu cần audit, message chỉ mang `patientUserId`, `appointmentId`, `sagaId`.

## Runtime Design
### Booking flow
1. `AppointmentService.createAppointment()` validate local + gRPC như hiện tại.
2. Persist `Appointment` với `BOOKING_PENDING`.
3. `AppointmentBookingSaga.startBooking()`:
   - upsert `AppointmentSaga(status=IN_PROGRESS, compensationIndex=0)`
   - persist `AppointmentPackageContext` với `roomSlotId`, `equipmentSlotId`
   - persist outbox `DOCTOR_RESERVE_COMMAND`
4. `OutboxPublisher` publish command ra exchange `appointment-exchange`.
5. Sau này plan 8 sẽ consume command và gửi reply.
6. `SagaReplyListener` nhận reply, check `InboxMessage`, rồi dispatch:
   - `DOCTOR_RESERVED` -> outbox `ROOM_SLOT_RESERVE_COMMAND`
   - `ROOM_SLOT_RESERVED` -> nếu không cần equipment thì confirm luôn, nếu có thì outbox `EQUIPMENT_SLOT_RESERVE_COMMAND`
   - `EQUIPMENT_SLOT_RESERVED` -> confirm appointment
   - reserve fail -> mark `BOOKING_FAILED`, trigger compensation releases nếu cần

### Cancel flow
1. `AppointmentService.cancelAppointment()` chỉ cho phép cancel khi `status == CONFIRMED`.
2. `AppointmentCancelSaga.startCancellation()`:
   - mark `CANCELLATION_PENDING`
   - upsert `AppointmentSaga(status=IN_PROGRESS)`
   - đọc `AppointmentResourceReservation` đã reserve
   - publish release command theo thứ tự `equipment -> room -> doctor`
3. `SagaReplyListener` handle release replies:
   - release success -> release tiếp resource còn lại
   - resource cuối cùng release xong -> mark `CANCELLED`
   - release fail -> mark `CANCELLATION_FAILED`

## Message Model
### Generic command envelope
`SagaCommand`
- `messageId`
- `appointmentId`
- `sagaId`
- `eventType`
- `patientUserId`
- `facilityId`
- `doctorId`
- `doctorScheduleId`
- `roomSlotId`
- `equipmentSlotId`

### Reply envelope
`SagaReply`
- `messageId`
- `appointmentId`
- `sagaId`
- `eventType`
- `doctorId`
- `doctorScheduleId`
- `roomSlotId`
- `equipmentSlotId`
- `errorCode`
- `errorMessage`

### Event types in use
- `DOCTOR_RESERVE_COMMAND`
- `ROOM_SLOT_RESERVE_COMMAND`
- `EQUIPMENT_SLOT_RESERVE_COMMAND`
- `DOCTOR_RELEASE_COMMAND`
- `ROOM_SLOT_RELEASE_COMMAND`
- `EQUIPMENT_SLOT_RELEASE_COMMAND`
- `DOCTOR_RESERVED`
- `DOCTOR_RESERVE_FAILED`
- `ROOM_SLOT_RESERVED`
- `ROOM_SLOT_RESERVE_FAILED`
- `EQUIPMENT_SLOT_RESERVED`
- `EQUIPMENT_SLOT_RESERVE_FAILED`
- `DOCTOR_RELEASED`
- `DOCTOR_RELEASE_FAILED`
- `ROOM_SLOT_RELEASED`
- `ROOM_SLOT_RELEASE_FAILED`
- `EQUIPMENT_SLOT_RELEASED`
- `EQUIPMENT_SLOT_RELEASE_FAILED`
- `APPOINTMENT_BOOKED`
- `APPOINTMENT_CANCELLED`

## RabbitMQ Topology
- Exchange: `appointment-exchange` (`topic`)
- Queue: `doctor-command-queue`
- Queue: `slot-command-queue`
- Queue: `appointment-reply-queue`

### Bindings
- `doctor-command-queue` <- `appointment.command.doctor.#`
- `slot-command-queue` <- `appointment.command.slot.#`
- `appointment-reply-queue` <- `appointment.reply.#`

## Persistence Model
### Existing tables reused
- `appointments`
- `appointment_sagas`
- `appointment_package_contexts`
- `appointment_resource_reservations`
- `outbox_events`
- `inbox_messages`

### Usage
- `AppointmentPackageContext` lưu chọn lựa booking cần cho bước async tiếp theo
- `AppointmentResourceReservation` track doctor/room/equipment đã reserve hay release
- `OutboxEvent` giữ command/event chưa publish
- `InboxMessage` chống duplicate reply processing

## Acceptance Criteria
- [x] RabbitMQ config và exchange/queue/binding được khai báo ở `appointment-service`
- [x] `AppointmentService.createAppointment()` trigger booking saga thay vì để TODO
- [x] `AppointmentService.cancelAppointment()` trigger cancel saga
- [x] Booking saga persist `AppointmentSaga`, `AppointmentPackageContext`, outbox command
- [x] Cancel saga release theo thứ tự ngược lại
- [x] Outbox polling publisher hoạt động
- [x] Reply listener có inbox idempotency
- [x] Unit tests cho booking/cancel saga pass
- [ ] End-to-end cross-service qua MQ

## Notes
- Message auth là **service-to-broker auth**, không phải user JWT.
- Vì plan 8 chưa làm, hiện tại saga mới orchestration được ở phía `appointment-service`.
- `AppointmentResourceReservation.targetId` hiện đang lưu `doctorId` cho doctor và `slotId` cho room/equipment. Có thể refine thêm ở plan 8 nếu downstream reply cung cấp target metadata đầy đủ hơn.
