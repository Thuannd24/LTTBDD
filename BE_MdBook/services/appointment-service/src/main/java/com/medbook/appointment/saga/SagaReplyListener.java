package com.medbook.appointment.saga;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.entity.InboxMessage;
import com.medbook.appointment.repository.InboxMessageRepository;
import java.util.Map;
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
public class SagaReplyListener {

    ObjectMapper objectMapper;
    InboxMessageRepository inboxMessageRepository;
    SagaReplyDispatcher sagaReplyDispatcher;

    @RabbitListener(
            queues = RabbitTopology.APPOINTMENT_REPLY_QUEUE,
            autoStartup = "${appointment.saga.reply-listener.auto-startup:true}")
    @Transactional
    public void handleSagaReply(SagaReply reply) {
        InboxMessage inboxMessage = inboxMessageRepository.findByMessageId(reply.getMessageId()).orElse(null);
        if (inboxMessage != null && Boolean.TRUE.equals(inboxMessage.getProcessed())) {
            log.info("Skipping duplicate saga reply {}", reply.getMessageId());
            return;
        }

        if (inboxMessage == null) {
            inboxMessage = InboxMessage.builder()
                    .messageId(reply.getMessageId())
                    .eventType(reply.getEventType().name())
                    .payload(objectMapper.convertValue(reply, new TypeReference<Map<String, Object>>() {
                    }))
                    .processed(false)
                    .build();
        }

        sagaReplyDispatcher.dispatch(reply);

        inboxMessage.setProcessed(true);
        inboxMessage.setEventType(reply.getEventType().name());
        inboxMessage.setPayload(objectMapper.convertValue(reply, new TypeReference<Map<String, Object>>() {
        }));
        inboxMessageRepository.save(inboxMessage);
    }
}
