# Plan 3: Naming Conventions & Code Pattern Alignment

## Summary of Cross-Service Patterns (Based on doctor-service analysis)

### 1. Response Wrapper
ALL endpoints wrap response in `ApiResponse<T>`:
```java
return ApiResponse.<AppointmentResponse>builder()
        .result(appointmentService.getAppointment(appointmentId))
        .build();
```

### 2. DTO Naming & Usage

| Operation | Pattern | Example |
|-----------|---------|---------|
| POST (Create) | `Create<Entity>Request` | `CreateAppointmentRequest` |
| PUT (Update) | `Update<Entity>Request` | `UpdateAppointmentRequest` |
| POST (Action) | `<Action><Entity>Request` | `CancelAppointmentRequest` |
| GET (Single) | `<Entity>Response` | `AppointmentResponse` |
| GET (Status) | `<Entity>StatusResponse` | `AppointmentStatusResponse` |
| Async Response | `Create<Entity>Response` (special) | `CreateAppointmentResponse` (202) |

### 3. Appointment Booking Flow DTOs

```java
// POST /appointments (async booking)
public ApiResponse<CreateAppointmentResponse> createAppointment(
    @RequestBody @Valid CreateAppointmentRequest request) {
    // Returns 202 Accepted with CreateAppointmentResponse
}

// GET /appointments/{id} (full details)
public ApiResponse<AppointmentResponse> getAppointment(@PathVariable String id) {
    // Returns 200 OK with AppointmentResponse
}

// GET /appointments/{id}/status (polling)
public ApiResponse<AppointmentStatusResponse> getAppointmentStatus(@PathVariable String id) {
    // Returns 200 OK with AppointmentStatusResponse
}

// POST /appointments/{id}/cancel (async cancellation)
public ApiResponse<AppointmentResponse> cancelAppointment(
    @PathVariable String id,
    @RequestBody @Valid CancelAppointmentRequest request) {
    // Returns 202 Accepted with AppointmentResponse (status=CANCELLATION_PENDING)
}
```

### 4. DTO Field Definitions

**CreateAppointmentRequest** (mutation input):
```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CreateAppointmentRequest {
    @NotBlank String packageId;
    @NotBlank String packageStepId;
    @NotBlank String doctorId;
    @NotNull Long doctorScheduleId;
    @NotNull Long roomSlotId;
    Long equipmentSlotId;
    String note;
}
```

**AppointmentResponse** (query output):
```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppointmentResponse {
    String id;
    String sagaId;
    String patientUserId;
    String doctorId;
    Long doctorScheduleId;
    String facilityId;
    String packageId;
    String packageStepId;
    String status;  // AppointmentStatus enum
    String note;
    String cancelReason;
    String failureCode;
    String failureMessage;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
```

**CreateAppointmentResponse** (202 response body):
```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CreateAppointmentResponse {
    String appointmentId;
    String sagaId;
    String status;  // Always BOOKING_PENDING
}
```

**AppointmentStatusResponse** (polling response):
```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppointmentStatusResponse {
    String status;
    String failureCode;
    String failureMessage;
}
```

**CancelAppointmentRequest** (cancel input):
```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CancelAppointmentRequest {
    @NotBlank String reason;
}
```

### 5. Controller Method Pattern

```java
@RestController
@RequestMapping("/appointments")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class AppointmentController {
    AppointmentService appointmentService;
    
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<CreateAppointmentResponse>> createAppointment(
            @RequestBody @Valid CreateAppointmentRequest request,
            @AuthenticationPrincipal JwtAuthenticationToken token) {
        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(ApiResponse.<CreateAppointmentResponse>builder()
                        .result(appointmentService.createAppointment(request, token))
                        .build());
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ApiResponse<AppointmentResponse> getAppointment(@PathVariable String id) {
        return ApiResponse.<AppointmentResponse>builder()
                .result(appointmentService.getAppointment(id))
                .build();
    }

    @GetMapping("/{id}/status")
    @PreAuthorize("isAuthenticated()")
    public ApiResponse<AppointmentStatusResponse> getAppointmentStatus(@PathVariable String id) {
        return ApiResponse.<AppointmentStatusResponse>builder()
                .result(appointmentService.getAppointmentStatus(id))
                .build();
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ApiResponse<Page<AppointmentResponse>> getMyAppointments(
            @AuthenticationPrincipal JwtAuthenticationToken token,
            Pageable pageable) {
        return ApiResponse.<Page<AppointmentResponse>>builder()
                .result(appointmentService.getMyAppointments(token.getName(), pageable))
                .build();
    }

    @GetMapping("/doctor/{doctorId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR')")
    public ApiResponse<Page<AppointmentResponse>> getDoctorAppointments(
            @PathVariable String doctorId,
            Pageable pageable) {
        return ApiResponse.<Page<AppointmentResponse>>builder()
                .result(appointmentService.getDoctorAppointments(doctorId, pageable))
                .build();
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AppointmentResponse>> cancelAppointment(
            @PathVariable String id,
            @RequestBody @Valid CancelAppointmentRequest request,
            @AuthenticationPrincipal JwtAuthenticationToken token) {
        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(ApiResponse.<AppointmentResponse>builder()
                        .result(appointmentService.cancelAppointment(id, request, token))
                        .build());
    }
}
```

### 6. Service Method Pattern

```java
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional
@Slf4j
public class AppointmentService {
    AppointmentRepository appointmentRepository;
    AppointmentMapper appointmentMapper;
    ExamPackageService packageService;
    ExamPackageStepService stepService;
    
    public CreateAppointmentResponse createAppointment(
            CreateAppointmentRequest request, 
            JwtAuthenticationToken token) {
        String patientUserId = token.getName();
        
        // Validate request
        validateCreateAppointmentRequest(request);
        
        // Generate IDs
        String appointmentId = generateId();
        String sagaId = generateId();
        
        // Create appointment entity
        Appointment appointment = Appointment.builder()
                .id(appointmentId)
                .sagaId(sagaId)
                .patientUserId(patientUserId)
                .doctorId(request.getDoctorId())
                .doctorScheduleId(request.getDoctorScheduleId())
                .packageId(request.getPackageId())
                .packageStepId(request.getPackageStepId())
                .status(Appointment.AppointmentStatus.BOOKING_PENDING)
                .note(request.getNote())
                .build();
        
        appointmentRepository.save(appointment);
        
        // Trigger saga (async) - TODO: gRPC call in Plan 5
        triggerBookingSaga(appointment, token);
        
        return CreateAppointmentResponse.builder()
                .appointmentId(appointmentId)
                .sagaId(sagaId)
                .status("BOOKING_PENDING")
                .build();
    }
    
    public AppointmentResponse getAppointment(String appointmentId) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found"));
        return appointmentMapper.toResponse(appointment);
    }
    
    public AppointmentStatusResponse getAppointmentStatus(String appointmentId) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found"));
        return AppointmentStatusResponse.builder()
                .status(appointment.getStatus().toString())
                .failureCode(appointment.getFailureCode())
                .failureMessage(appointment.getFailureMessage())
                .build();
    }
}
```

### 7. Mapper Pattern

```java
@Mapper(componentModel = "spring")
public interface AppointmentMapper {
    
    @Mapping(target = "status", source = "status", qualifiedByName = "statusToString")
    AppointmentResponse toResponse(Appointment entity);
    
    @Named("statusToString")
    static String statusToString(Appointment.AppointmentStatus status) {
        return status != null ? status.toString() : null;
    }
}
```

### 8. HTTP Status Codes Used in Plan 3

| Endpoint | Method | Status |
|----------|--------|--------|
| POST /appointments | POST | 202 Accepted (async) |
| GET /appointments/{id} | GET | 200 OK |
| GET /appointments/{id}/status | GET | 200 OK |
| GET /appointments/my | GET | 200 OK (paginated) |
| GET /appointments/doctor/{id} | GET | 200 OK (paginated) |
| POST /appointments/{id}/cancel | POST | 202 Accepted (async) |

---

## Alignment with Other Services

✅ Uses `ApiResponse<T>` wrapper (like doctor-service, profile-service)
✅ Request/Response DTOs follow naming convention (Create*, Update*, *Response)
✅ Action-specific requests (CancelAppointmentRequest) for non-CRUD operations
✅ Async operations return 202 Accepted
✅ Validates using `@Valid` on @RequestBody
✅ Uses `@PreAuthorize` for method-level security
✅ MapStruct mapper pattern for entity ↔ DTO conversion
✅ Follows Lombok convention (@Data, @Builder, @FieldDefaults)
