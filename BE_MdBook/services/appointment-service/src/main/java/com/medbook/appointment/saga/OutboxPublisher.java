package com.medbook.appointment.saga;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.entity.OutboxEvent;
import com.medbook.appointment.repository.OutboxEventRepository;
import java.util.List;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class OutboxPublisher {

    OutboxEventRepository outboxEventRepository;
    ObjectMapper objectMapper;
    RabbitTemplate rabbitTemplate;

    @Scheduled(fixedDelayString = "${appointment.saga.outbox.publish-interval-ms:1000}")
    @Transactional
    public void publishPendingEvents() {
        List<OutboxEvent> pendingEvents = outboxEventRepository.findTop50ByPublishedFalseOrderByCreatedAtAsc();
        for (OutboxEvent pendingEvent : pendingEvents) {
            try {
                SagaEventType eventType = SagaEventType.valueOf(pendingEvent.getEventType());
                SagaCommand payload = objectMapper.convertValue(pendingEvent.getPayload(), SagaCommand.class);
                rabbitTemplate.convertAndSend(
                        RabbitTopology.APPOINTMENT_EXCHANGE,
                        RabbitTopology.routingKeyFor(eventType),
                        payload);
                pendingEvent.setPublished(true);
                outboxEventRepository.save(pendingEvent);
            } catch (Exception ex) {
                log.warn("Failed to publish outbox event {}: {}", pendingEvent.getId(), ex.getMessage());
            }
        }
    }
}
