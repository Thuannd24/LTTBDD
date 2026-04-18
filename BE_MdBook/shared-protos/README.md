# shared-protos

Shared gRPC contracts for MedBook services.

## Structure

- src/main/proto/doctor/doctor-service.proto
- src/main/proto/slot/slot-service.proto

## Build

```bash
mvn clean install
```

This generates protobuf classes and gRPC stubs, then installs artifact:

- groupId: com.medbook
- artifactId: shared-protos
- version: 0.0.1

## Use In Another Service

Add dependency:

```xml
<dependency>
  <groupId>com.medbook</groupId>
  <artifactId>shared-protos</artifactId>
  <version>0.0.1</version>
</dependency>
```

Then import generated classes, for example:

- com.medbook.grpc.doctor.DoctorServiceGrpc
- com.medbook.grpc.slot.SlotServiceGrpc
