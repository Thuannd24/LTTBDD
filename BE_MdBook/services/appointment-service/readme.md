# Appointment Service

`appointment-service` điều phối đặt lịch theo kiểu synchronous.

## Trách nhiệm

- validate package, doctor, room, equipment
- reserve tài nguyên qua REST/Feign
- persist appointment và reservation state
- cancel appointment và release tài nguyên ngay trong request

## Ghi chú

- Service chỉ còn flow đồng bộ qua REST/Feign.
- Không còn lớp orchestration bất đồng bộ cũ.

## Chạy test

```bash
mvn -B -ntp clean test
```
