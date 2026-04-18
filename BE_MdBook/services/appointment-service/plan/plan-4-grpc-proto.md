# Plan 4: gRPC Setup & Proto Definitions

## Phạm vi
Tạo proto files và gRPC stub framework (chưa implement business logic).

## Tasks
### 4.1 Tạo Shared Proto Module
- Tạo thư mục: `shared-protos/` hoặc `grpc-contracts/`
- Structure:
  ```
  shared-protos/
  ├── src/main/proto/
  │   ├── doctor/
  │   │   └── doctor-service.proto
  │   └── slot/
  │       └── slot-service.proto
  ├── pom.xml (configure protobuf plugin)
  └── README.md
  ```

### 4.2 Định nghĩa Doctor Service Proto
File: `doctor-service.proto`
```protobuf
syntax = "proto3";
package com.medbook.grpc.doctor;

service DoctorService {
  rpc GetDoctorById(GetDoctorByIdRequest) returns (DoctorResponse);
  rpc GetDoctorScheduleById(GetDoctorScheduleByIdRequest) returns (DoctorScheduleResponse);
}

message GetDoctorByIdRequest {
  string doctor_id = 1;
}

message DoctorResponse {
  string id = 1;
  string name = 2;
  string specialty_id = 3;
  repeated string allowed_specialty_ids = 4;
  bool active = 5;
}

message GetDoctorScheduleByIdRequest {
  string schedule_id = 1;
  string doctor_id = 2;
}

message DoctorScheduleResponse {
  string id = 1;
  string doctor_id = 2;
  string date = 3;
  string start_time = 4;
  string end_time = 5;
  bool available = 6;
}
```

### 4.3 Định nghĩa Slot Service Proto
File: `slot-service.proto`
```protobuf
syntax = "proto3";
package com.medbook.grpc.slot;

service SlotService {
  rpc GetSlotById(GetSlotByIdRequest) returns (SlotResponse);
  rpc GetRoomById(GetRoomByIdRequest) returns (RoomResponse);
  rpc GetEquipmentById(GetEquipmentByIdRequest) returns (EquipmentResponse);
}

message GetSlotByIdRequest {
  string slot_id = 1;
}

message SlotResponse {
  string id = 1;
  string target_type = 2; // ROOM or EQUIPMENT
  string target_id = 3;
  string date = 4;
  string start_time = 5;
  string end_time = 6;
  bool available = 7;
}

message GetRoomByIdRequest {
  string room_id = 1;
}

message RoomResponse {
  string id = 1;
  string name = 2;
  string category = 3; // NORMAL_ROOM, ULTRASOUND_ROOM, LAB_ROOM, etc.
  bool active = 4;
}

message GetEquipmentByIdRequest {
  string equipment_id = 1;
}

message EquipmentResponse {
  string id = 1;
  string name = 2;
  string type = 3; // ULTRASOUND_MACHINE, XRAY_MACHINE, etc.
  bool active = 4;
}
```

### 4.4 Configure Protobuf Maven Plugin
- Thêm `protobuf-maven-plugin` vào `pom.xml`
- Config generate `.pb.java` files vào target/generated-sources
- Cấu hình `grpc-java-codegen` plugin để generate gRPC stubs

### 4.5 Add gRPC Dependencies
- Thêm `io.grpc:grpc-netty-shaded`
- Thêm `io.grpc:grpc-protobuf`
- Thêm `io.grpc:grpc-stub`
- Thêm `com.google.protobuf:protobuf-java`

### 4.6 Build & Verify
- Run `mvn clean compile` để generate proto code
- Verify `.pb.java` và gRPC stub classes generate thành công
- Commit proto files + generated stubs

## Acceptance Criteria
- [ ] Shared proto module tạo thành công
- [ ] 2 proto files (doctor + slot) định nghĩa đầy đủ
- [ ] Maven build generate Java code + gRPC stubs
- [ ] Generated files có thể import/use ở appointment-service
- [ ] Doctor-service và slot-service có thể import proto từ shared module

## Notes
- **Chưa implement services** - chỉ proto definitions
- **gRPC servers sẽ implement ở plan tiếp theo**

## Estimate
**1-1.5 giờ** (proto definitions, maven config, build verification)
