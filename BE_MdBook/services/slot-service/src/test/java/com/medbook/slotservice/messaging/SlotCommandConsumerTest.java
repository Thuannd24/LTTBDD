package com.medbook.slotservice.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.slotservice.dto.request.BookSlotRequest;
import com.medbook.slotservice.entity.InboxMessage;
import com.medbook.slotservice.exception.AppException;
import com.medbook.slotservice.exception.ErrorCode;
import com.medbook.slotservice.repository.InboxMessageRepository;
import com.medbook.slotservice.service.SlotService;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
@DisplayName("SlotCommandConsumer Unit Tests")
class SlotCommandConsumerTest {

    @Mock
    SlotService slotService;

    @Mock
    InboxMessageRepository inboxMessageRepository;

    @Mock
    SlotReplyProducer slotReplyProducer;

    @InjectMocks
    SlotCommandConsumer slotCommandConsumer;

    @Test
    @DisplayName("handleCommand reserves room slot and emits success reply")
    void handleRoomReserveSuccess() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-1")
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .eventType(SagaEventType.ROOM_SLOT_RESERVE_COMMAND)
                .roomSlotId(21L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-1")).thenReturn(Optional.empty());

        slotCommandConsumer.handleCommand(command);

        ArgumentCaptor<BookSlotRequest> requestCaptor = ArgumentCaptor.forClass(BookSlotRequest.class);
        verify(slotService).reserveSlot(eq(21L), requestCaptor.capture());
        assertThat(requestCaptor.getValue().getAppointmentId()).isEqualTo("apt-1");

        ArgumentCaptor<SagaReply> replyCaptor = ArgumentCaptor.forClass(SagaReply.class);
        verify(slotReplyProducer).sendReply(replyCaptor.capture());
        assertThat(replyCaptor.getValue().getEventType()).isEqualTo(SagaEventType.ROOM_SLOT_RESERVED);
        assertThat(replyCaptor.getValue().getRoomSlotId()).isEqualTo(21L);

        ArgumentCaptor<InboxMessage> inboxCaptor = ArgumentCaptor.forClass(InboxMessage.class);
        verify(inboxMessageRepository).save(inboxCaptor.capture());
        assertThat(inboxCaptor.getValue().getProcessed()).isTrue();
    }

    @Test
    @DisplayName("handleCommand emits failure reply when equipment reserve throws AppException")
    void handleEquipmentReserveFailure() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-2")
                .appointmentId("apt-2")
                .sagaId("saga-2")
                .eventType(SagaEventType.EQUIPMENT_SLOT_RESERVE_COMMAND)
                .equipmentSlotId(22L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-2")).thenReturn(Optional.empty());
        when(slotService.reserveSlot(eq(22L), any(BookSlotRequest.class)))
                .thenThrow(new AppException(ErrorCode.SLOT_ALREADY_RESERVED));

        slotCommandConsumer.handleCommand(command);

        ArgumentCaptor<SagaReply> replyCaptor = ArgumentCaptor.forClass(SagaReply.class);
        verify(slotReplyProducer).sendReply(replyCaptor.capture());
        assertThat(replyCaptor.getValue().getEventType()).isEqualTo(SagaEventType.EQUIPMENT_SLOT_RESERVE_FAILED);
        assertThat(replyCaptor.getValue().getErrorCode()).isEqualTo(ErrorCode.SLOT_ALREADY_RESERVED.name());
    }

    @Test
    @DisplayName("handleCommand releases room slot and emits success reply")
    void handleRoomReleaseSuccess() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-3")
                .appointmentId("apt-3")
                .sagaId("saga-3")
                .eventType(SagaEventType.ROOM_SLOT_RELEASE_COMMAND)
                .roomSlotId(23L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-3")).thenReturn(Optional.empty());

        slotCommandConsumer.handleCommand(command);

        verify(slotService).releaseSlot(23L, "apt-3");
        ArgumentCaptor<SagaReply> replyCaptor = ArgumentCaptor.forClass(SagaReply.class);
        verify(slotReplyProducer).sendReply(replyCaptor.capture());
        assertThat(replyCaptor.getValue().getEventType()).isEqualTo(SagaEventType.ROOM_SLOT_RELEASED);
    }

    @Test
    @DisplayName("handleCommand skips duplicate processed command")
    void handleDuplicateProcessedCommand() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-4")
                .eventType(SagaEventType.ROOM_SLOT_RESERVE_COMMAND)
                .roomSlotId(24L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-4"))
                .thenReturn(Optional.of(InboxMessage.builder()
                        .messageId("msg-4")
                        .commandType(SagaEventType.ROOM_SLOT_RESERVE_COMMAND.name())
                        .processed(true)
                        .build()));

        slotCommandConsumer.handleCommand(command);

        verify(slotService, never()).reserveSlot(any(), any());
        verify(slotService, never()).releaseSlot(any(), any());
        verify(slotReplyProducer, never()).sendReply(any());
        verify(inboxMessageRepository, never()).save(any());
    }
}
