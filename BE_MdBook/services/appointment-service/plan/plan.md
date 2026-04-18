
Plan

Kế Hoạch appointment-service: Package Model + Saga MQ + gRPC Sync
Tóm tắt
Chốt kiến trúc theo hướng:

appointment-service là source-of-truth cho ExamPackage và booking rule
async write path dùng RabbitMQ saga + outbox
sync read/validation path dùng gRPC, không dùng REST
doctor-service và slot-service vẫn giữ REST public hiện tại cho frontend/admin
service-to-service nội bộ giữa appointment -> doctor/slot dùng gRPC + Keycloak client credentials
.proto đặt trong module dùng chung
V1 chỉ book một step cụ thể của package trên mỗi appointment.

Thay đổi chính
1. Domain trong appointment-service
Thêm các aggregate:

ExamPackage
ExamPackageStep
Appointment
AppointmentPackageContext
AppointmentResourceReservation
AppointmentSaga
OutboxEvent
InboxMessage
ExamPackage:

id, code, name, description, status
estimatedTotalMinutes
audit fields
ExamPackageStep:

id, packageId, stepOrder, stepName
allowedSpecialtyIds
requiredRoomCategory
requiredEquipmentType nếu có
equipmentRequired
estimatedMinutes
note
Appointment:

id, sagaId
patientUserId
doctorId, doctorScheduleId
facilityId
packageId, packageStepId
status, note
cancelReason
failureCode, failureMessage
audit fields
AppointmentResourceReservation:

appointmentId
slotId
targetType
targetId
status
V1 status tối thiểu:

BOOKING_PENDING
CONFIRMED
BOOKING_FAILED
CANCELLATION_PENDING
CANCELLED
CANCELLATION_FAILED
2. Public APIs và request shape
appointment-service giữ vai trò booking-focused.

Package APIs:

GET /exam-packages
GET /exam-packages/{id}
GET /exam-packages/{id}/steps
admin CRUD cho package và step
Appointment APIs:

POST /appointments
GET /appointments/{id}
GET /appointments/{id}/status
GET /appointments/my
GET /appointments/doctor/{doctorId}
POST /appointments/{id}/cancel
Request tạo appointment:

{
  "packageId": "pkg-general-checkup",
  "packageStepId": "step-ultrasound",
  "doctorId": "doctor-123",
  "doctorScheduleId": 101,
  "roomSlotId": 202,
  "equipmentSlotId": 303,
  "note": "Follow-up visit"
}
Rule validate trong appointment-service:

doctor phải có specialty thuộc allowedSpecialtyIds
doctor schedule phải thuộc đúng doctor
room slot phải khớp requiredRoomCategory
equipment slot phải khớp requiredEquipmentType nếu step yêu cầu
step không cần equipment thì không cho gửi equipmentSlotId
step cần equipment thì bắt buộc có equipmentSlotId
Response:

POST /appointments trả 202 Accepted
chứa appointmentId, sagaId, status=BOOKING_PENDING
3. gRPC sync path
Dùng gRPC cho toàn bộ service-to-service sync read/validation giữa:

appointment-service -> doctor-service
appointment-service -> slot-service
Giữ REST public hiện tại ở doctor-service và slot-service; không thay frontend/admin sang gRPC.

Tạo shared proto module chứa contract.

Doctor gRPC tối thiểu:

GetDoctorById
GetDoctorScheduleById
GetDoctorScheduleAvailability nếu cần phase sau
Slot gRPC tối thiểu:

GetSlotById
GetRoomById
GetEquipmentById
không cần aggregate availability ở appointment-service v1
Auth gRPC:

(Tạm thời) forward user token từ request xuống gRPC
appointment-service extract JWT từ Authorization header
gửi token đó trực tiếp tới doctor-service và slot-service
downstream authorize theo user identity
TODO: V2 chuyển sang Keycloak client credentials
4. Saga và RabbitMQ
Dùng orchestrated saga với RabbitMQ và outbox.

Write path vẫn hoàn toàn qua MQ:

DOCTOR_RESERVE
ROOM_SLOT_RESERVE
EQUIPMENT_SLOT_RESERVE
các command release tương ứng khi compensate hoặc cancel
Booking saga:

validate package step qua local DB
validate doctor/schedule/room/equipment qua gRPC
tạo Appointment với BOOKING_PENDING
lưu AppointmentPackageContext
ghi outbox command DOCTOR_RESERVE
nhận success thì gửi ROOM_SLOT_RESERVE
nếu có equipment thì gửi EQUIPMENT_SLOT_RESERVE
khi hoàn tất, mark CONFIRMED
lưu AppointmentResourceReservation
publish notification event
Compensation:

doctor success, room fail -> release doctor
room success, equipment fail -> release room rồi doctor
finalize DB fail sau khi reserve downstream -> release toàn bộ resource đã reserve và mark BOOKING_FAILED
Cancel saga:

validate quyền và trạng thái
mark CANCELLATION_PENDING
release equipment nếu có
release room
release doctor schedule
mark CANCELLED
publish notification event
doctor-service và slot-service:

thêm Rabbit consumer + reply producer ngay trong chính service
không tách worker riêng
dùng inbox/processed-message để idempotent
5. Test và tiêu chí hoàn thành
Test package validation:

doctor đúng specialty
doctor sai specialty bị reject
room slot sai category bị reject
equipment slot sai type bị reject
thiếu equipment khi step bắt buộc bị reject
Test gRPC integration:

appointment-service gọi được doctor gRPC với machine token
appointment-service gọi được slot gRPC với machine token
unauthorized internal call bị reject
Test saga:

booking success với room-only
booking success với room + equipment
doctor reserve fail
room reserve fail sau doctor success
equipment reserve fail sau room success
duplicate reply handling
cancel release đủ tất cả reservation downstream
Acceptance criteria:

package rule nằm hoàn toàn ở appointment-service
sync validation path dùng gRPC, không dùng REST
async orchestration path dùng RabbitMQ
frontend/staff không phải nhớ bằng tay quan hệ doctor-machine-package
booking request bị reject nếu selection không khớp package step
cancel luôn compensate đủ doctor/resource reservation
Giả định đã chốt
ExamPackage thuộc appointment-service
package model là multi-step
v1 mỗi appointment chỉ book một step
patient chọn doctor trong tập doctor phù hợp package
staff/UI vẫn chọn room/equipment candidate, backend validate chặt
doctor-service và slot-service giữ REST public song song với gRPC nội bộ
.proto nằm trong module dùng chung
gRPC nội bộ (tạm thời) forward user JWT, chưa dùng Keycloak client credentials
