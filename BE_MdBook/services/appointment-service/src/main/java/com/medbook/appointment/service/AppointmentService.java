package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.request.CreateAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.dto.response.CreateAppointmentResponse;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.exception.SlotNotFoundException;
import com.medbook.appointment.grpc.client.DoctorGrpcClient;
import com.medbook.appointment.grpc.client.SlotGrpcClient;
import com.medbook.appointment.grpc.model.DoctorInfo;
import com.medbook.appointment.grpc.model.DoctorScheduleInfo;
import com.medbook.appointment.grpc.model.EquipmentInfo;
import com.medbook.appointment.grpc.model.RoomInfo;
import com.medbook.appointment.grpc.model.SlotInfo;
import com.medbook.appointment.mapper.AppointmentMapper;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.saga.AppointmentBookingSaga;
import com.medbook.appointment.saga.AppointmentCancelSaga;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional
@Slf4j
public class AppointmentService {
    
    AppointmentRepository appointmentRepository;
    AppointmentMapper appointmentMapper;
    ExamPackageService examPackageService;
    ExamPackageStepService examPackageStepService;
    DoctorGrpcClient doctorGrpcClient;
    SlotGrpcClient slotGrpcClient;
    AppointmentBookingSaga appointmentBookingSaga;
    AppointmentCancelSaga appointmentCancelSaga;
    
    /**
     * Tạo appointment booking mới (async) - thực hiện saga validation
     * 
     * @param request CreateAppointmentRequest với packageId, doctorId, etc.
     * @param patientUserId ID của patient từ token
     * @return CreateAppointmentResponse với appointmentId, sagaId, status=BOOKING_PENDING
     */
    public CreateAppointmentResponse createAppointment(
            CreateAppointmentRequest request,
            String patientUserId) {
        
        log.info("Creating appointment for user: {} with package: {}", patientUserId, request.getPackageId());
        
        // Validate request
        validateCreateAppointmentRequest(request);
        
        // Create appointment entity with BOOKING_PENDING status
        Appointment appointment = Appointment.builder()
                .patientUserId(patientUserId)
                .doctorId(request.getDoctorId())
                .doctorScheduleId(request.getDoctorScheduleId())
                .facilityId(request.getFacilityId() != null ? request.getFacilityId() : "default")
                .packageId(request.getPackageId())
                .packageStepId(request.getPackageStepId())
                .status(Appointment.AppointmentStatus.BOOKING_PENDING)
                .note(request.getNote())
                .build();
        
        Appointment saved = appointmentRepository.save(appointment);
        appointmentBookingSaga.startBooking(saved, request);
        log.info("Appointment created: {} with saga: {}", saved.getId(), saved.getSagaId());
        
        return CreateAppointmentResponse.builder()
                .appointmentId(saved.getId())
                .sagaId(saved.getSagaId())
                .status("BOOKING_PENDING")
                .build();
    }
    
    /**
     * Lấy thông tin appointment đầy đủ từ DB
     * 
     * @param appointmentId ID của appointment
     * @return AppointmentResponse chứa đầy đủ thông tin
     */
    @Transactional(readOnly = true)
    public AppointmentResponse getAppointment(String appointmentId) {
        log.debug("Fetching appointment: {}", appointmentId);
        
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));
        
        return appointmentMapper.toResponse(appointment);
    }
    
    /**
     * Lấy status appointment hiện tại (cho polling)
     * 
     * @param appointmentId ID của appointment
     * @return AppointmentStatusResponse chỉ chứa { status, failureCode, failureMessage }
     */
    @Transactional(readOnly = true)
    public AppointmentStatusResponse getAppointmentStatus(String appointmentId) {
        log.debug("Fetching appointment status: {}", appointmentId);
        
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));
        
        return appointmentMapper.toStatusResponse(appointment);
    }
    
    /**
     * Lấy danh sách appointments của user hiện tại (paginated)
     * 
     * @param patientUserId ID của user
     * @param pageable pagination info
     * @return Page<AppointmentResponse> danh sách appointments của user
     */
    @Transactional(readOnly = true)
    public Page<AppointmentResponse> getMyAppointments(String patientUserId, Pageable pageable) {
        log.debug("Fetching appointments for patient: {}", patientUserId);
        
        return appointmentRepository
                .findByPatientUserId(patientUserId, pageable)
                .map(appointmentMapper::toResponse);
    }
    
    /**
     * Lấy danh sách appointments của doctor (paginated)
     * 
     * @param doctorId ID của doctor
     * @param pageable pagination info
     * @return Page<AppointmentResponse> danh sách appointments của doctor
     */
    @Transactional(readOnly = true)
    public Page<AppointmentResponse> getDoctorAppointments(String doctorId, Pageable pageable) {
        log.debug("Fetching appointments for doctor: {}", doctorId);
        
        return appointmentRepository
                .findByDoctorId(doctorId, pageable)
                .map(appointmentMapper::toResponse);
    }
    
    /**
     * Hủy appointment (async) - thực hiện saga cancellation
     * 
     * @param appointmentId ID của appointment
     * @param request CancelAppointmentRequest chứa reason
     * @param patientUserId ID của user từ token
     * @return AppointmentResponse với status=CANCELLATION_PENDING
     */
    public AppointmentResponse cancelAppointment(
            String appointmentId,
            CancelAppointmentRequest request,
            String patientUserId) {
        
        log.info("Cancelling appointment: {} for user: {}", appointmentId, patientUserId);
        
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));
        
        // Validate user is owner
        if (!appointment.getPatientUserId().equals(patientUserId)) {
            throw new AppointmentAccessDeniedException("Unauthorized to cancel this appointment");
        }
        
        Appointment updatedAppointment = appointmentCancelSaga.startCancellation(appointment, request.getReason());
        log.info("Appointment cancellation initiated: {}", appointmentId);

        return appointmentMapper.toResponse(updatedAppointment);
    }
    
    /**
     * Validate CreateAppointmentRequest
     */
    private void validateCreateAppointmentRequest(CreateAppointmentRequest request) {
        // Validate required fields are not null.
        if (request.getDoctorId() == null || request.getDoctorId().isBlank()) {
            throw new AppointmentValidationException("Doctor ID is required");
        }

        if (request.getDoctorScheduleId() == null) {
            throw new AppointmentValidationException("Doctor schedule ID is required");
        }

        if (request.getRoomSlotId() == null) {
            throw new AppointmentValidationException("Room slot ID is required");
        }

        // Validate package from local data.
        try {
            examPackageService.getPackageById(request.getPackageId());
        } catch (Exception e) {
            throw new AppointmentValidationException("Package not found: " + request.getPackageId());
        }

        // Validate package step if provided (optional)
        ExamPackageStepResponse stepResponse = null;
        if (request.getPackageStepId() != null && !request.getPackageStepId().isBlank()) {
            try {
                stepResponse = examPackageStepService.getStepById(request.getPackageStepId());
            } catch (Exception e) {
                throw new AppointmentValidationException("Package step not found: " + request.getPackageStepId());
            }

            if (!Objects.equals(stepResponse.getPackageId(), request.getPackageId())) {
                throw new AppointmentValidationException("Package step does not belong to the selected package");
            }
        }

        // Validate doctor and schedule via doctor-service gRPC.
        DoctorInfo doctorInfo = doctorGrpcClient.getDoctorById(request.getDoctorId());
        if (!doctorInfo.active()) {
            throw new AppointmentValidationException("Doctor is inactive: " + request.getDoctorId());
        }

        DoctorScheduleInfo scheduleInfo = doctorGrpcClient.getDoctorScheduleById(
                String.valueOf(request.getDoctorScheduleId()),
                request.getDoctorId()
        );
        if (!Objects.equals(scheduleInfo.doctorId(), request.getDoctorId())) {
            throw new AppointmentValidationException("Doctor schedule does not belong to the selected doctor");
        }
        if (!scheduleInfo.available()) {
            throw new DoctorScheduleNotFoundException("Doctor schedule is not available: " + request.getDoctorScheduleId());
        }

        if (stepResponse != null) {
            validateSpecialty(stepResponse, doctorInfo);
            validateRoomAndEquipment(stepResponse, request);
        }
    }

    private void validateSpecialty(ExamPackageStepResponse stepResponse, DoctorInfo doctorInfo) {
        if (stepResponse.getAllowedSpecialtyIds() == null || stepResponse.getAllowedSpecialtyIds().isEmpty()) {
            return;
        }

        if (doctorInfo.specialtyId() == null || doctorInfo.specialtyId().isBlank()) {
            throw new AppointmentValidationException("Doctor specialty is missing");
        }

        if (!stepResponse.getAllowedSpecialtyIds().contains(doctorInfo.specialtyId())) {
            throw new AppointmentValidationException("Doctor specialty is not allowed for this package step");
        }
    }

    private void validateRoomAndEquipment(ExamPackageStepResponse stepResponse, CreateAppointmentRequest request) {
        SlotInfo roomSlot = slotGrpcClient.getSlotById(String.valueOf(request.getRoomSlotId()));
        if (!"ROOM".equalsIgnoreCase(roomSlot.targetType())) {
            throw new SlotNotFoundException("Room slot target type must be ROOM");
        }
        if (!roomSlot.available()) {
            throw new AppointmentValidationException("Room slot is not available: " + request.getRoomSlotId());
        }

        RoomInfo roomInfo = slotGrpcClient.getRoomById(roomSlot.targetId());
        if (!roomInfo.active()) {
            throw new AppointmentValidationException("Room is inactive: " + roomInfo.id());
        }

        if (stepResponse.getRequiredRoomCategory() != null
                && !stepResponse.getRequiredRoomCategory().isBlank()
                && !stepResponse.getRequiredRoomCategory().equalsIgnoreCase(roomInfo.category())) {
            throw new AppointmentValidationException("Room category does not match package step requirement");
        }

        if (!Boolean.TRUE.equals(stepResponse.getEquipmentRequired())) {
            if (request.getEquipmentSlotId() != null) {
                throw new AppointmentValidationException("Equipment slot must not be provided for this package step");
            }
            return;
        }

        if (request.getEquipmentSlotId() == null) {
            throw new AppointmentValidationException("Equipment slot ID is required for this package step");
        }

        SlotInfo equipmentSlot = slotGrpcClient.getSlotById(String.valueOf(request.getEquipmentSlotId()));
        if (!"EQUIPMENT".equalsIgnoreCase(equipmentSlot.targetType())) {
            throw new SlotNotFoundException("Equipment slot target type must be EQUIPMENT");
        }
        if (!equipmentSlot.available()) {
            throw new AppointmentValidationException("Equipment slot is not available: " + request.getEquipmentSlotId());
        }

        EquipmentInfo equipmentInfo = slotGrpcClient.getEquipmentById(equipmentSlot.targetId());
        if (!equipmentInfo.active()) {
            throw new AppointmentValidationException("Equipment is inactive: " + equipmentInfo.id());
        }

        if (stepResponse.getRequiredEquipmentType() != null
                && !stepResponse.getRequiredEquipmentType().isBlank()
                && !stepResponse.getRequiredEquipmentType().equalsIgnoreCase(equipmentInfo.type())) {
            throw new AppointmentValidationException("Equipment type does not match package step requirement");
        }
    }
}
