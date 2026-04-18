# Slot Service Refactor Plan

## Goal

Refactor `slot-service` thành service quản lý:

- loại phòng
- phòng cụ thể
- thiết bị trong phòng
- slot của phòng
- slot của thiết bị

Thiết kế này phải phục vụ được flow cuối:

1. client chọn gói khám
2. hệ thống biết gói đó đi qua những loại phòng nào
3. mỗi loại phòng có nhiều phòng cụ thể
4. khi chọn được phòng:
   - nếu phòng có nhiều máy thì chọn máy trống trong phòng
   - nếu phòng chỉ có 1 máy thì tự chọn

`facility` là cấp cao nhất. Không có cấp lớn hơn `facility`.

## Business Boundary

### `slot-service` should own

- room categories
- rooms inside a facility
- equipments inside a room
- recurring schedule config for rooms/equipments
- room slots
- equipment slots
- availability query for room/equipment
- reserve / release / block of room/equipment slots

### `slot-service` should not own

- doctor profile
- doctor working schedule
- appointment lifecycle
- package catalog definition

### `appointment-service` will later own

- package selection
- orchestration of booking flow
- reservation of doctor schedule
- reservation of room slot
- reservation of equipment slot when required

## Final Business Flow

Target flow:

1. client chọn `gói khám`
2. `appointment-service` đọc danh sách `roomCategory` mà gói khám cần đi qua
3. với mỗi `roomCategory`, hệ thống gọi `slot-service` để tìm các room còn trống
4. client hoặc hệ thống chọn `room`
5. nếu room đó có nhiều equipment cần chọn:
   - gọi `slot-service` để tìm equipment còn trống trong room
   - client chọn machine
6. nếu room chỉ có 1 equipment phù hợp:
   - tự động chọn
7. `appointment-service` reserve doctor schedule, room slot, equipment slot
8. persist appointment

## Domain Model

## 1. RoomCategory

Đây là loại phòng theo công năng.

Recommended values:

- `CONSULTATION_ROOM`
- `ULTRASOUND_ROOM`
- `XRAY_ROOM`
- `ENDOSCOPY_ROOM`
- `PROCEDURE_ROOM`
- `RECOVERY_ROOM`
- `INPATIENT_ROOM`
- `MULTI_PURPOSE_ROOM`

Room category không nên nhét vào `ResourceType`. Nó là business classification của room.

## 2. Room

Represents a concrete room in a facility.

Recommended fields:

- `id: String`
- `roomCode: String`
- `roomName: String`
- `facilityId: Long`
- `roomCategory: RoomCategory`
- `status: RoomStatus`
- `notes: String`
- `createdAt: LocalDateTime`
- `updatedAt: LocalDateTime`

Recommended statuses:

- `ACTIVE`
- `INACTIVE`
- `MAINTENANCE`

Examples:

- `room-101` -> `CONSULTATION_ROOM`
- `room-201` -> `ULTRASOUND_ROOM`
- `room-301` -> `XRAY_ROOM`

## 3. Equipment

Represents a concrete machine or attached device inside a room.

Recommended fields:

- `id: String`
- `equipmentCode: String`
- `equipmentName: String`
- `facilityId: Long`
- `roomId: String`
- `equipmentType: EquipmentType`
- `status: EquipmentStatus`
- `notes: String`
- `createdAt: LocalDateTime`
- `updatedAt: LocalDateTime`

Recommended equipment types:

- `ULTRASOUND_MACHINE`
- `XRAY_MACHINE`
- `ECG_MACHINE`
- `ENDOSCOPY_MACHINE`
- `MONITOR`
- `OTHER`

Recommended statuses:

- `ACTIVE`
- `INACTIVE`
- `MAINTENANCE`

Examples:

- `us-201-a` in `room-201`
- `xray-301-a` in `room-301`

## 4. RecurringSlotConfig

Keep the recurring idea, but redefine it completely.

It should apply to a schedulable target:

- room
- equipment

Recommended fields:

- `id: Long`
- `targetType: SlotTargetType`
- `targetId: String`
- `facilityId: Long`
- `dayOfWeek: DayOfWeek`
- `startTime: LocalTime`
- `endTime: LocalTime`
- `slotDurationMinutes: Integer`
- `status: RecurringStatus`
- `createdAt: LocalDateTime`
- `updatedAt: LocalDateTime`

Recommended target types:

- `ROOM`
- `EQUIPMENT`

This replaces current `resourceId/resourceType` semantics.

## 5. Slot

This should become a generic schedulable slot, but tied to either a room or an equipment.

Recommended fields:

- `id: Long`
- `targetType: SlotTargetType`
- `targetId: String`
- `facilityId: Long`
- `startTime: LocalDateTime`
- `endTime: LocalDateTime`
- `status: SlotStatus`
- `appointmentId: Long`
- `notes: String`
- `recurringConfigId: Long`
- `createdAt: LocalDateTime`
- `updatedAt: LocalDateTime`

Recommended statuses:

- `AVAILABLE`
- `RESERVED`
- `BLOCKED`

Important:

- room slots and equipment slots are stored separately by `targetType`
- the same time window can exist for a room and its equipment, but they are different slots

## 6. SlotHistory

Keep slot history.

Recommended fields:

- `id`
- `slotId`
- `statusFrom`
- `statusTo`
- `appointmentId`
- `reason`
- `changedAt`

## Enum Design

### Replace current `ResourceType`

Current `ResourceType` is too flat for the final business flow.

Recommended replacement:

- `SlotTargetType`
  - `ROOM`
  - `EQUIPMENT`

### Add `RoomCategory`

As above, business categories of rooms.

### Add `EquipmentType`

As above, concrete equipment categories.

## Data Relationships

### facility

Root of everything.

### room

- belongs to one `facility`

### equipment

- belongs to one `facility`
- belongs to one `room`

### recurring config

- belongs to either one room or one equipment

### slot

- belongs to either one room or one equipment

### slot history

- belongs to one slot

## What `slot-service` must answer

It must answer:

- which rooms of a category are available at a given date/time
- which equipments inside a room are available at a given date/time
- whether a room slot can be reserved
- whether an equipment slot can be reserved

It must not answer:

- whether doctor A is working
- whether a full medical package is valid

## API Design

## Room APIs

- `POST /rooms`
- `GET /rooms/{roomId}`
- `GET /rooms`
- `PUT /rooms/{roomId}`
- `DELETE /rooms/{roomId}`

Recommended query filters:

- `facilityId`
- `roomCategory`
- `status`

## Equipment APIs

- `POST /equipments`
- `GET /equipments/{equipmentId}`
- `GET /equipments`
- `PUT /equipments/{equipmentId}`
- `DELETE /equipments/{equipmentId}`
- `GET /rooms/{roomId}/equipments`

Recommended query filters:

- `facilityId`
- `roomId`
- `equipmentType`
- `status`

## Recurring Config APIs

- `POST /schedule-configs`
- `GET /schedule-configs/{id}`
- `GET /schedule-configs`
- `PUT /schedule-configs/{id}`
- `DELETE /schedule-configs/{id}`

Recommended query filters:

- `targetType`
- `targetId`
- `facilityId`

## Availability APIs

### Find available rooms by category

- `GET /slots/rooms/available`

Recommended query:

- `facilityId`
- `roomCategory`
- `date`
- optional `limit`

### Find available equipments in room

- `GET /slots/equipments/available`

Recommended query:

- `facilityId`
- `roomId`
- optional `equipmentType`
- `date`
- optional `limit`

## Slot Reservation APIs

- `POST /slots/{slotId}/reserve`
- `POST /slots/{slotId}/release`
- `POST /slots/{slotId}/block`
- `GET /slots/{slotId}/history`

Reserve request:

```json
{
  "appointmentId": 42
}
```

## Business Rules

1. One room slot can belong to at most one active appointment.
2. One equipment slot can belong to at most one active appointment.
3. A blocked slot cannot be reserved.
4. A released slot returns to `AVAILABLE`.
5. A room may have zero, one, or many equipments.
6. Not every room has the same set of equipments.
7. If a room category normally needs equipment:
   - and room has one valid equipment -> auto-pick
   - and room has many valid equipments -> user or orchestration must choose one
8. `slot-service` only exposes availability and reservation data; package logic stays outside.

## Cache Design

Current cache key should be redesigned.

Recommended cache keys:

- `slot:rooms:{facilityId}:{roomCategory}:{date}`
- `slot:equipments:{facilityId}:{roomId}:{equipmentType?}:{date}`

Invalidation rules:

- reserve / release / block room slot -> invalidate room availability cache of that facility/category/date
- reserve / release / block equipment slot -> invalidate equipment availability cache of that room/date

## Persistence Rules

## Room

Recommended indexes:

- `facility_id, room_category`
- `facility_id, status`

Recommended unique constraint:

- `facility_id + room_code`

## Equipment

Recommended indexes:

- `facility_id, room_id`
- `room_id, equipment_type`
- `room_id, status`

Recommended unique constraint:

- `facility_id + equipment_code`

## RecurringSlotConfig

Recommended unique constraint:

- `target_type + target_id + day_of_week + start_time + end_time`

## Slot

Recommended indexes:

- `target_type, target_id, start_time`
- `facility_id, start_time, status`
- `status, start_time`

Recommended unique constraint:

- `target_type + target_id + start_time + end_time`

## Integration with `appointment-service`

`appointment-service` will later use this flow:

1. get available rooms by required room category
2. choose room
3. if package step needs equipment, get available equipments in room
4. choose or auto-pick equipment
5. reserve room slot
6. reserve equipment slot if needed
7. persist appointment

Important:

- package definition does not belong to `slot-service`
- `slot-service` only provides room/equipment availability and reservation primitives

## Suggested Future Appointment Side Model

This is not implemented in `slot-service`, but should be considered while designing contracts.

Recommended child table in `appointment-service`:

`AppointmentResourceReservation`

Fields:

- `appointmentId`
- `slotId`
- `targetType`
- `targetId`

This allows one appointment to reserve:

- one room slot
- zero or one equipment slot
- potentially more in future

## Migration Strategy

Current `slot-service` has already been partially refactored once. That intermediate model should not be extended further.

Recommended migration:

### Phase 0: Freeze old model

- stop expanding current `resourceId/resourceType` model
- keep existing code only as temporary compatibility baseline

### Phase 1: Introduce new core tables

- add `Room`
- add `Equipment`
- redefine `RecurringSlotConfig`
- redefine `Slot` around `targetType/targetId`

### Phase 2: Rebuild services

- rebuild repositories
- rebuild generator
- rebuild cache
- rebuild availability queries
- rebuild reserve/release/block logic

### Phase 3: Rebuild controllers

- add room APIs
- add equipment APIs
- add room availability APIs
- add equipment availability APIs
- keep old APIs temporarily only if migration compatibility is needed

### Phase 4: Rebuild tests

- room tests
- equipment tests
- recurring generation tests
- reserve/release/block tests
- cache invalidation tests

### Phase 5: Update gateway and downstream contracts

- update docs
- update `appointment-service` plan
- update frontend/API clients

## Acceptance Criteria

The refactor is complete when:

- `slot-service` no longer models doctor availability
- facility is the top-level boundary
- room is the central schedulable business unit
- equipment belongs to a room
- not all rooms are forced to share the same equipment set
- room availability can be queried by room category
- equipment availability can be queried inside a room
- room and equipment slots can be reserved/released/blocked independently
- contracts are ready for package-based appointment orchestration

## Recommended Implementation Order

1. define final enums and entities
2. implement `Room`
3. implement `Equipment`
4. redefine `RecurringSlotConfig`
5. redefine `Slot`
6. rewrite generator
7. rewrite service layer
8. rewrite controller layer
9. rewrite tests
10. update gateway/docs/contracts
