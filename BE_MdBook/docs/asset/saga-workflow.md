# MedBook Appointment Saga Workflow

Tài liệu này mô tả chi tiết các kịch bản của luồng đặt lịch khám (Appointment Booking) sử dụng Saga Pattern (Choreography/Orchestration-based) trong hệ thống Microservices MedBook.

---

## 1. Kịch bản Thành công (Happy Path)
Đây là trường hợp lý tưởng khi tất cả tài nguyên (Bác sĩ, Phòng, Máy) đều sẵn sàng.

```mermaid
sequenceDiagram
    autonumber
    participant P as Bệnh nhân (Frontend)
    participant A as Appointment Service (Saga)
    participant D as Doctor Service
    participant S as Slot Service (Room/Equip)

    P->>A: POST /appointments (Start Saga)
    Note over A: Khởi tạo Saga: Status = IN_PROGRESS
    A->>D: [RabbitMQ] DOCTOR_RESERVE_COMMAND
    D-->>A: [RabbitMQ] DOCTOR_RESERVED
    Note over A: CompensationIndex = 1

    A->>S: [RabbitMQ] ROOM_SLOT_RESERVE_COMMAND
    S-->>A: [RabbitMQ] ROOM_SLOT_RESERVED
    Note over A: CompensationIndex = 2

    A->>S: [RabbitMQ] EQUIPMENT_SLOT_RESERVE_COMMAND
    S-->>A: [RabbitMQ] EQUIPMENT_SLOT_RESERVED
    Note over A: CompensationIndex = 3

    Note over A: Status = COMPLETED
    A->>P: Trả về trạng thái CONFIRMED (Async)
```

---

## 2. Kịch bản Lỗi tại bước Khóa Phòng (Rollback Bác sĩ)
Xảy ra khi Bác sĩ rảnh nhưng căn phòng vừa bị người khác đặt mất hoặc gặp sự cố kỹ thuật tại Slot Service.

```mermaid
sequenceDiagram
    autonumber
    participant P as Bệnh nhân
    participant A as Appointment Service
    participant D as Doctor Service
    participant S as Slot Service

    P->>A: Yêu cầu đặt lịch
    A->>D: Khóa Bác sĩ (Reserve Order)
    D-->>A: Bác sĩ OK (Reserved)
    
    A->>S: Khóa Phòng (Room Slot)
    S-->>A: LỖI: ROOM_SLOT_RESERVE_FAILED
    
    Note over A: BẮT ĐẦU ROLLBACK (Đền bù)
    A->>D: [RabbitMQ] DOCTOR_RELEASE_COMMAND
    D-->>A: Bác sĩ đã được giải phóng (Released)
    
    Note over A: Saga Status = COMPENSATED
    A->>P: Báo lỗi: Đặt lịch thất bại (Phòng bận)
```

---

## 3. Kịch bản Lỗi tại bước Khóa Thiết Bị (Rollback Phức Tạp)
Đây là kịch bản hoàn tác toàn bộ khi các tài nguyên trước đó đã OK nhưng tài nguyên cuối cùng thất bại.

```mermaid
sequenceDiagram
    autonumber
    participant A as Appointment Service
    participant D as Doctor Service
    participant S as Slot Service

    Note right of A: Đăng ký Bác sĩ & Phòng thành công
    A->>S: [RabbitMQ] Khóa thiết bị (Equipment)
    S-->>A: LỖI: EQUIPMENT_SLOT_RESERVE_FAILED

    Note over A: TIẾN TRÌNH HOÀN TÁC (ROLLBACK)
    A->>S: [RabbitMQ] Giải phóng Phòng (ROOM_SLOT_RELEASE)
    S-->>A: Phòng đã rảnh lại (Released)
    
    A->>D: [RabbitMQ] Giải phóng Bác sĩ (DOCTOR_RELEASE)
    D-->>A: Bác sĩ đã rảnh lại (Released)

    Note over A: Saga Status = FAILED/COMPENSATED
    A->>A: Hủy Appointment (Status: BOOKING_FAILED)
```

---

## 4. Chi tiết Kỹ thuật (Technical Notes)

| Đại lượng | Chi tiết |
| :--- | :--- |
| **Cơ chế truyền tin** | RabbitMQ (Asynchronous Messaging) |
| **Logic Rollback** | Dựa trên `compensationIndex` trong database để xác định các bước đã thực hiện thành công và cần đảo ngược. |
| **Hàm xử lý chính** | `handleReply` và `handleCompensationReleased` trong `AppointmentBookingSaga.java`. |
| **Tình trạng nhất quán** | Đạt mức **Eventual Consistency** (Nhất quán sau cùng). |

---
*Tài liệu được sinh tự động bởi Antigravity AI Assistant.*
