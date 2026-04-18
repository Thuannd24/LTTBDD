package com.medbook.slotservice.messaging;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SlotReplyProducer {

    RabbitTemplate rabbitTemplate;

    public void sendReply(SagaReply reply) {
        rabbitTemplate.convertAndSend(
                RabbitTopology.APPOINTMENT_EXCHANGE,
                RabbitTopology.replyRoutingKey(reply.getEventType()),
                reply);
    }
}
