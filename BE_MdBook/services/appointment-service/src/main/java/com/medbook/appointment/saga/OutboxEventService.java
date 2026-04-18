package com.medbook.appointment.saga;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.entity.OutboxEvent;
import com.medbook.appointment.repository.OutboxEventRepository;
import java.util.Map;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class OutboxEventService {

    ObjectMapper objectMapper;
    OutboxEventRepository outboxEventRepository;

    @Transactional
    public OutboxEvent enqueue(String aggregateId, SagaEventType eventType, SagaCommand payload) {
        OutboxEvent outboxEvent = OutboxEvent.builder()
                .aggregateId(aggregateId)
                .eventType(eventType.name())
                .payload(objectMapper.convertValue(payload, new TypeReference<Map<String, Object>>() {
                }))
                .published(false)
                .build();
        return outboxEventRepository.save(outboxEvent);
    }
}
