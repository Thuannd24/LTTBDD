package com.medbook.doctor.messaging;

import com.medbook.doctor.dto.request.DoctorScheduleReserveRequest;
import com.medbook.doctor.entity.InboxMessage;
import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import com.medbook.doctor.repository.InboxMessageRepository;
import com.medbook.doctor.service.DoctorScheduleService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class DoctorCommandConsumer {

    DoctorScheduleService doctorScheduleService;
    InboxMessageRepository inboxMessageRepository;
    DoctorReplyProducer doctorReplyProducer;

    @RabbitListener(
            queues = RabbitTopology.DOCTOR_COMMAND_QUEUE,
            autoStartup = "${doctor.messaging.listeners.auto-startup:true}")
    @Transactional
    public void handleCommand(SagaCommand command) {
        if (command == null || command.getMessageId() == null || command.getMessageId().isBlank()) {
            log.warn("Skipping doctor command with missing messageId");
            return;
        }

        InboxMessage inboxMessage = inboxMessageRepository.findByMessageId(command.getMessageId()).orElse(null);
        if (inboxMessage != null && Boolean.TRUE.equals(inboxMessage.getProcessed())) {
            log.info("Skipping duplicate doctor command {}", command.getMessageId());
            return;
        }

        if (inboxMessage == null) {
            inboxMessage = InboxMessage.builder()
                    .messageId(command.getMessageId())
                    .commandType(command.getEventType().name())
                    .processed(false)
                    .build();
        }

        SagaReply reply = processCommand(command);
        doctorReplyProducer.sendReply(reply);

        inboxMessage.setProcessed(true);
        inboxMessage.setCommandType(command.getEventType().name());
        inboxMessageRepository.save(inboxMessage);
    }

    private SagaReply processCommand(SagaCommand command) {
        try {
            return switch (command.getEventType()) {
                case DOCTOR_RESERVE_COMMAND -> handleReserve(command);
                case DOCTOR_RELEASE_COMMAND -> handleRelease(command);
                default -> buildFailureReply(command, SagaEventType.DOCTOR_RESERVE_FAILED, "UNSUPPORTED_EVENT", "Unsupported doctor command");
            };
        } catch (AppException ex) {
            SagaEventType failureEventType = command.getEventType() == SagaEventType.DOCTOR_RELEASE_COMMAND
                    ? SagaEventType.DOCTOR_RELEASE_FAILED
                    : SagaEventType.DOCTOR_RESERVE_FAILED;
            return buildFailureReply(command, failureEventType, ex.getErrorCode().name(), ex.getMessage());
        } catch (Exception ex) {
            SagaEventType failureEventType = command.getEventType() == SagaEventType.DOCTOR_RELEASE_COMMAND
                    ? SagaEventType.DOCTOR_RELEASE_FAILED
                    : SagaEventType.DOCTOR_RESERVE_FAILED;
            return buildFailureReply(command, failureEventType, ErrorCode.UNCATEGORIZED_EXCEPTION.name(), ex.getMessage());
        }
    }

    private SagaReply handleReserve(SagaCommand command) {
        doctorScheduleService.reserveSchedule(
                command.getDoctorScheduleId(),
                DoctorScheduleReserveRequest.builder()
                        .appointmentId(command.getAppointmentId())
                        .build());

        return SagaReply.builder()
                .messageId(command.getMessageId())
                .appointmentId(command.getAppointmentId())
                .sagaId(command.getSagaId())
                .eventType(SagaEventType.DOCTOR_RESERVED)
                .doctorId(command.getDoctorId())
                .doctorScheduleId(command.getDoctorScheduleId())
                .build();
    }

    private SagaReply handleRelease(SagaCommand command) {
        doctorScheduleService.releaseSchedule(command.getDoctorScheduleId(), command.getAppointmentId());

        return SagaReply.builder()
                .messageId(command.getMessageId())
                .appointmentId(command.getAppointmentId())
                .sagaId(command.getSagaId())
                .eventType(SagaEventType.DOCTOR_RELEASED)
                .doctorId(command.getDoctorId())
                .doctorScheduleId(command.getDoctorScheduleId())
                .build();
    }

    private SagaReply buildFailureReply(SagaCommand command, SagaEventType eventType, String errorCode, String errorMessage) {
        return SagaReply.builder()
                .messageId(command.getMessageId())
                .appointmentId(command.getAppointmentId())
                .sagaId(command.getSagaId())
                .eventType(eventType)
                .doctorId(command.getDoctorId())
                .doctorScheduleId(command.getDoctorScheduleId())
                .errorCode(errorCode)
                .errorMessage(errorMessage)
                .build();
    }
}
