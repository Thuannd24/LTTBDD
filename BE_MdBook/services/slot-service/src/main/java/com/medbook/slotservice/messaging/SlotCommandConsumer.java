package com.medbook.slotservice.messaging;

import com.medbook.slotservice.dto.request.BookSlotRequest;
import com.medbook.slotservice.entity.InboxMessage;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.repository.InboxMessageRepository;
import com.medbook.slotservice.service.SlotService;
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
public class SlotCommandConsumer {

    SlotService slotService;
    InboxMessageRepository inboxMessageRepository;
    SlotReplyProducer slotReplyProducer;

    @RabbitListener(
            queues = RabbitTopology.SLOT_COMMAND_QUEUE,
            autoStartup = "${slot.messaging.listeners.auto-startup:true}")
    @Transactional
    public void handleCommand(SagaCommand command) {
        if (command == null || command.getMessageId() == null || command.getMessageId().isBlank()) {
            log.warn("Skipping slot command with missing messageId");
            return;
        }

        InboxMessage inboxMessage = inboxMessageRepository.findByMessageId(command.getMessageId()).orElse(null);
        if (inboxMessage != null && Boolean.TRUE.equals(inboxMessage.getProcessed())) {
            log.info("Skipping duplicate slot command {}", command.getMessageId());
            return;
        }

        if (command.getEventType() == null) {
            log.warn("Skipping slot command {} with missing eventType", command.getMessageId());
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
        slotReplyProducer.sendReply(reply);

        inboxMessage.setProcessed(true);
        inboxMessage.setCommandType(command.getEventType().name());
        inboxMessageRepository.save(inboxMessage);
    }

    private SagaReply processCommand(SagaCommand command) {
        try {
            return switch (command.getEventType()) {
                case ROOM_SLOT_RESERVE_COMMAND -> handleReserve(command, command.getRoomSlotId(), SagaEventType.ROOM_SLOT_RESERVED);
                case EQUIPMENT_SLOT_RESERVE_COMMAND ->
                        handleReserve(command, command.getEquipmentSlotId(), SagaEventType.EQUIPMENT_SLOT_RESERVED);
                case ROOM_SLOT_RELEASE_COMMAND -> handleRelease(command, command.getRoomSlotId(), SagaEventType.ROOM_SLOT_RELEASED);
                case EQUIPMENT_SLOT_RELEASE_COMMAND ->
                        handleRelease(command, command.getEquipmentSlotId(), SagaEventType.EQUIPMENT_SLOT_RELEASED);
                default -> buildFailureReply(
                        command,
                        failureEventType(command.getEventType()),
                        "UNSUPPORTED_EVENT",
                        "Unsupported slot command");
            };
        } catch (AppException ex) {
            return buildFailureReply(command, failureEventType(command.getEventType()), ex.getErrorCode().name(), ex.getMessage());
        } catch (Exception ex) {
            return buildFailureReply(
                    command,
                    failureEventType(command.getEventType()),
                    ErrorCode.UNCATEGORIZED_EXCEPTION.name(),
                    ex.getMessage());
        }
    }

    private SagaReply handleReserve(SagaCommand command, Long slotId, SagaEventType successEventType) {
        BookSlotRequest request = new BookSlotRequest();
        request.setAppointmentId(command.getAppointmentId());
        slotService.reserveSlot(slotId, request);

        return SagaReply.builder()
                .messageId(command.getMessageId())
                .appointmentId(command.getAppointmentId())
                .sagaId(command.getSagaId())
                .eventType(successEventType)
                .roomSlotId(command.getRoomSlotId())
                .equipmentSlotId(command.getEquipmentSlotId())
                .build();
    }

    private SagaReply handleRelease(SagaCommand command, Long slotId, SagaEventType successEventType) {
        slotService.releaseSlot(slotId, command.getAppointmentId());

        return SagaReply.builder()
                .messageId(command.getMessageId())
                .appointmentId(command.getAppointmentId())
                .sagaId(command.getSagaId())
                .eventType(successEventType)
                .roomSlotId(command.getRoomSlotId())
                .equipmentSlotId(command.getEquipmentSlotId())
                .build();
    }

    private SagaEventType failureEventType(SagaEventType commandEventType) {
        return switch (commandEventType) {
            case ROOM_SLOT_RESERVE_COMMAND -> SagaEventType.ROOM_SLOT_RESERVE_FAILED;
            case EQUIPMENT_SLOT_RESERVE_COMMAND -> SagaEventType.EQUIPMENT_SLOT_RESERVE_FAILED;
            case ROOM_SLOT_RELEASE_COMMAND -> SagaEventType.ROOM_SLOT_RELEASE_FAILED;
            case EQUIPMENT_SLOT_RELEASE_COMMAND -> SagaEventType.EQUIPMENT_SLOT_RELEASE_FAILED;
            default -> SagaEventType.ROOM_SLOT_RESERVE_FAILED;
        };
    }

    private SagaReply buildFailureReply(
            SagaCommand command,
            SagaEventType eventType,
            String errorCode,
            String errorMessage) {
        return SagaReply.builder()
                .messageId(command.getMessageId())
                .appointmentId(command.getAppointmentId())
                .sagaId(command.getSagaId())
                .eventType(eventType)
                .roomSlotId(command.getRoomSlotId())
                .equipmentSlotId(command.getEquipmentSlotId())
                .errorCode(errorCode)
                .errorMessage(errorMessage)
                .build();
    }
}
