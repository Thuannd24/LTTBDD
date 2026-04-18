# System Entity Relationship Overview (Liên thông dữ liệu) - Đã cập nhật chuẩn 100%

Sơ đồ mô tả mối quan hệ logic của dữ liệu dựa trên mã nguồn thực tế của các Entity trong hệ thống MedBook.

```mermaid
erDiagram
    IDENTITY_DB ||--|| PROFILE_DB : "userId (1:1)"
    PROFILE_DB ||--o{ APPOINTMENT_DB : "patientUserId (1:N)"
    DOCTOR_DB ||--o{ APPOINTMENT_DB : "doctorId (1:N)"
    DOCTOR_DB ||--o{ DOCTOR_SCHEDULE : "has (1:N)"
    DOCTOR_SCHEDULE ||--o| APPOINTMENT_DB : "references (1:1)"
    SLOT_DB ||--o| APPOINTMENT_DB : "references (1:1)"
    
    subgraph Identity Service
        IDENTITY_DB {
            string id PK "UUID"
            string username
            string email
        }
    end

    subgraph Profile Service
        PROFILE_DB {
            string id PK "UUID"
            string userId FK "Reference Identity"
            string fullName
            string insuranceNumber
        }
    end

    subgraph Doctor Service
        DOCTOR_DB {
            string id PK "UUID"
            string userId FK "Reference Identity"
            Set_string specialtyIds
            string status "PENDING/ACTIVE"
        }
        DOCTOR_SCHEDULE {
            long id PK
            string doctorId FK
            datetime startTime
            datetime endTime
            string status "AVAILABLE/RESERVED"
            string appointmentId FK "Reference Appointment"
        }
    end

    subgraph Slot Service
        SLOT_DB {
            long id PK
            string targetId "Room/Equip ID"
            string targetType "ROOM/EQUIPMENT"
            string status "AVAILABLE/RESERVED"
            string appointmentId FK "Reference Appointment"
        }
    end

    subgraph Appointment Service
        APPOINTMENT_DB {
            string id PK "UUID"
            string sagaId
            string patientUserId FK
            string doctorId FK
            long doctorScheduleId FK
            string status "BOOKING_PENDING/CONFIRMED/FAILED"
        }
    end
```

## Các điểm kỹ thuật chính chủ

1.  **Định danh (Identifiers)**: 
    *   Hầu hết các thực thể chính (`User`, `Doctor`, `Appointment`) sử dụng **UUID (String)** để đảm bảo tính duy nhất trên toàn hệ thống phân tán.
    *   Các thực thể phụ hoặc mang tính thời điểm (`Slot`, `DoctorSchedule`) sử dụng **Long (Auto-increment)** để tối ưu hiệu năng truy vấn theo thời gian.
2.  **Tính nhất quán qua Saga**:
    *   Khi `Appointment` ở trạng thái `BOOKING_PENDING`, các ID của nó sẽ được gửi sang `Doctor` và `Slot` service để thực hiện lệnh "Khóa" (Reserve).
    *   Chỉ khi nhận được phản hồi thành công từ tất cả, `Appointment` mới chuyển sang `CONFIRMED`.
3.  **Dữ liệu Chat**: Dịch vụ Chat lưu trữ trong MongoDB với cấu trúc Schema-less nên không xuất hiện trong sơ đồ quan hệ chặt chẽ này, nhưng nó liên kết với các dịch vụ khác qua `participantId` (chính là `userId`).
