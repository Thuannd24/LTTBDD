package com.medbook.slotservice.configuration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.slotservice.messaging.RabbitTopology;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Declarables;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableRabbit
public class SlotRabbitMqConfiguration {

    @Bean
    public TopicExchange appointmentExchange() {
        return new TopicExchange(RabbitTopology.APPOINTMENT_EXCHANGE, true, false);
    }

    @Bean
    public Queue slotCommandQueue() {
        return new Queue(RabbitTopology.SLOT_COMMAND_QUEUE, true);
    }

    @Bean
    public Declarables slotBindings(TopicExchange appointmentExchange, Queue slotCommandQueue) {
        return new Declarables(
                BindingBuilder.bind(slotCommandQueue)
                        .to(appointmentExchange)
                        .with("appointment.command.slot.#"));
    }

    @Bean
    public MessageConverter rabbitMessageConverter(ObjectMapper objectMapper) {
        return new Jackson2JsonMessageConverter(objectMapper);
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory, MessageConverter rabbitMessageConverter) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        rabbitTemplate.setMessageConverter(rabbitMessageConverter);
        return rabbitTemplate;
    }
}
