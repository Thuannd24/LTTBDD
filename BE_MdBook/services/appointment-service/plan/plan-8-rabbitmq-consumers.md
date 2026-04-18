# Plan 8: RabbitMQ Consumers (Doctor-Service & Slot-Service)

## Scope
Doctor-service and slot-service consume saga commands published by appointment-service and send reply events back through the shared RabbitMQ exchange.

## Runtime Model
- Broker auth is service-to-broker only via `spring.rabbitmq.*`.
- User JWT is not forwarded through RabbitMQ messages.
- Each downstream service owns one command queue:
  - `doctor-command-queue`
  - `slot-command-queue`
- Each downstream service uses one consumer class with an event-type switch instead of one class per command.
- Idempotency uses `InboxMessage(messageId, commandType, processed)`.

## Doctor-Service

### Tasks
- Add `spring-boot-starter-amqp`.
- Add `DoctorRabbitMqConfiguration`:
  - declare `appointment-exchange`
  - declare `doctor-command-queue`
  - bind queue to `appointment.command.doctor.#`
  - configure `Jackson2JsonMessageConverter`
- Implement `DoctorReplyProducer`:
  - send `SagaReply` to `appointment-exchange`
  - routing keys:
    - `appointment.reply.doctor.reserved`
    - `appointment.reply.doctor.reserve-failed`
    - `appointment.reply.doctor.released`
    - `appointment.reply.doctor.release-failed`
- Implement `DoctorCommandConsumer`:
  - consume `DOCTOR_RESERVE_COMMAND`
  - consume `DOCTOR_RELEASE_COMMAND`
  - call existing `DoctorScheduleService.reserveSchedule(...)`
  - call existing `DoctorScheduleService.releaseSchedule(...)`
  - convert `AppException` to failure replies
  - mark inbox record processed after reply publish
- Add tests:
  - reserve success
  - reserve failure
  - release success
  - duplicate command skip

## Slot-Service

### Tasks
- Add `spring-boot-starter-amqp`.
- Add `SlotRabbitMqConfiguration`:
  - declare `appointment-exchange`
  - declare `slot-command-queue`
  - bind queue to `appointment.command.slot.#`
  - configure `Jackson2JsonMessageConverter`
- Implement `SlotReplyProducer`:
  - send `SagaReply` to `appointment-exchange`
  - routing keys:
    - `appointment.reply.slot.room.reserved`
    - `appointment.reply.slot.room.reserve-failed`
    - `appointment.reply.slot.equipment.reserved`
    - `appointment.reply.slot.equipment.reserve-failed`
    - `appointment.reply.slot.room.released`
    - `appointment.reply.slot.room.release-failed`
    - `appointment.reply.slot.equipment.released`
    - `appointment.reply.slot.equipment.release-failed`
- Implement `SlotCommandConsumer`:
  - consume `ROOM_SLOT_RESERVE_COMMAND`
  - consume `EQUIPMENT_SLOT_RESERVE_COMMAND`
  - consume `ROOM_SLOT_RELEASE_COMMAND`
  - consume `EQUIPMENT_SLOT_RELEASE_COMMAND`
  - call existing `SlotService.reserveSlot(...)`
  - call existing `SlotService.releaseSlot(...)`
  - convert `AppException` to failure replies
  - mark inbox record processed after reply publish
- Add tests:
  - room reserve success
  - equipment reserve failure
  - room release success
  - duplicate command skip

## Configuration
- `doctor-service`:
  - `spring.rabbitmq.host`
  - `spring.rabbitmq.port`
  - `spring.rabbitmq.username`
  - `spring.rabbitmq.password`
  - `doctor.messaging.listeners.auto-startup`
- `slot-service`:
  - `spring.rabbitmq.host`
  - `spring.rabbitmq.port`
  - `spring.rabbitmq.username`
  - `spring.rabbitmq.password`
  - `slot.messaging.listeners.auto-startup`
- `docker-compose.yml` updates:
  - `doctor-service` depends on `rabbitmq`
  - `slot-service` depends on `rabbitmq`
  - both services use `SPRING_RABBIT_HOST=rabbitmq`

## Acceptance Criteria
- [ ] Doctor-service consumer starts and handles reserve/release commands.
- [ ] Slot-service consumer starts and handles room/equipment reserve/release commands.
- [ ] Reply producers emit success/failure events with routing keys expected by appointment-service.
- [ ] Inbox idempotency prevents duplicate command execution.
- [ ] Unit tests pass for doctor-service and slot-service messaging layers.
- [ ] docker-compose wires both downstream services to RabbitMQ.

## Full Saga Smoke After Plan 8
1. `POST /appointments` on appointment-service.
2. Appointment-service publishes `DOCTOR_RESERVE_COMMAND`.
3. Doctor-service consumes it and publishes `DOCTOR_RESERVED`.
4. Appointment-service publishes the next room or equipment command.
5. Slot-service consumes it and publishes the matching success or failure reply.
6. Appointment-service updates appointment status to `CONFIRMED` or compensates.
