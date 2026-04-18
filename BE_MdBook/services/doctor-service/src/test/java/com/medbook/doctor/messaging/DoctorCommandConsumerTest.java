package com.medbook.doctor.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.doctor.dto.request.DoctorScheduleReserveRequest;
import com.medbook.doctor.entity.InboxMessage;
import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import com.medbook.doctor.repository.InboxMessageRepository;
import com.medbook.doctor.service.DoctorScheduleService;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
@DisplayName("DoctorCommandConsumer Unit Tests")
class DoctorCommandConsumerTest {

    @Mock
    DoctorScheduleService doctorScheduleService;

    @Mock
    InboxMessageRepository inboxMessageRepository;

    @Mock
    DoctorReplyProducer doctorReplyProducer;

    @InjectMocks
    DoctorCommandConsumer doctorCommandConsumer;

    @Test
    @DisplayName("handleCommand reserves schedule and emits success reply")
    void handleReserveSuccess() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-1")
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .eventType(SagaEventType.DOCTOR_RESERVE_COMMAND)
                .doctorId("doctor-1")
                .doctorScheduleId(11L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-1")).thenReturn(Optional.empty());

        doctorCommandConsumer.handleCommand(command);

        ArgumentCaptor<DoctorScheduleReserveRequest> requestCaptor = ArgumentCaptor.forClass(DoctorScheduleReserveRequest.class);
        verify(doctorScheduleService).reserveSchedule(eq(11L), requestCaptor.capture());
        assertThat(requestCaptor.getValue().getAppointmentId()).isEqualTo("apt-1");

        ArgumentCaptor<SagaReply> replyCaptor = ArgumentCaptor.forClass(SagaReply.class);
        verify(doctorReplyProducer).sendReply(replyCaptor.capture());
        assertThat(replyCaptor.getValue().getEventType()).isEqualTo(SagaEventType.DOCTOR_RESERVED);
        assertThat(replyCaptor.getValue().getDoctorScheduleId()).isEqualTo(11L);

        ArgumentCaptor<InboxMessage> inboxCaptor = ArgumentCaptor.forClass(InboxMessage.class);
        verify(inboxMessageRepository).save(inboxCaptor.capture());
        assertThat(inboxCaptor.getValue().getProcessed()).isTrue();
        assertThat(inboxCaptor.getValue().getCommandType()).isEqualTo(SagaEventType.DOCTOR_RESERVE_COMMAND.name());
    }

    @Test
    @DisplayName("handleCommand skips duplicate processed command")
    void handleDuplicateProcessedCommand() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-2")
                .eventType(SagaEventType.DOCTOR_RESERVE_COMMAND)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-2"))
                .thenReturn(Optional.of(InboxMessage.builder()
                        .messageId("msg-2")
                        .commandType(SagaEventType.DOCTOR_RESERVE_COMMAND.name())
                        .processed(true)
                        .build()));

        doctorCommandConsumer.handleCommand(command);

        verify(doctorScheduleService, never()).reserveSchedule(any(), any());
        verify(doctorReplyProducer, never()).sendReply(any());
        verify(inboxMessageRepository, never()).save(any());
    }

    @Test
    @DisplayName("handleCommand emits failure reply when reserve throws AppException")
    void handleReserveFailure() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-3")
                .appointmentId("apt-3")
                .sagaId("saga-3")
                .eventType(SagaEventType.DOCTOR_RESERVE_COMMAND)
                .doctorId("doctor-1")
                .doctorScheduleId(99L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-3")).thenReturn(Optional.empty());
        when(doctorScheduleService.reserveSchedule(eq(99L), any()))
                .thenThrow(new AppException(ErrorCode.DOCTOR_SCHEDULE_ALREADY_RESERVED));

        doctorCommandConsumer.handleCommand(command);

        ArgumentCaptor<SagaReply> replyCaptor = ArgumentCaptor.forClass(SagaReply.class);
        verify(doctorReplyProducer).sendReply(replyCaptor.capture());
        assertThat(replyCaptor.getValue().getEventType()).isEqualTo(SagaEventType.DOCTOR_RESERVE_FAILED);
        assertThat(replyCaptor.getValue().getErrorCode()).isEqualTo(ErrorCode.DOCTOR_SCHEDULE_ALREADY_RESERVED.name());
    }

    @Test
    @DisplayName("handleCommand releases schedule and emits success reply")
    void handleReleaseSuccess() {
        SagaCommand command = SagaCommand.builder()
                .messageId("msg-4")
                .appointmentId("apt-4")
                .sagaId("saga-4")
                .eventType(SagaEventType.DOCTOR_RELEASE_COMMAND)
                .doctorId("doctor-1")
                .doctorScheduleId(33L)
                .build();
        when(inboxMessageRepository.findByMessageId("msg-4")).thenReturn(Optional.empty());

        doctorCommandConsumer.handleCommand(command);

        verify(doctorScheduleService).releaseSchedule(33L, "apt-4");
        ArgumentCaptor<SagaReply> replyCaptor = ArgumentCaptor.forClass(SagaReply.class);
        verify(doctorReplyProducer).sendReply(replyCaptor.capture());
        assertThat(replyCaptor.getValue().getEventType()).isEqualTo(SagaEventType.DOCTOR_RELEASED);
    }
}
