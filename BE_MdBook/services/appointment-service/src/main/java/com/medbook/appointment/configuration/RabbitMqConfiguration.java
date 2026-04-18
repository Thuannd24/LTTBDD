package com.medbook.appointment.configuration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.saga.RabbitTopology;
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
public class RabbitMqConfiguration {

    @Bean
    public TopicExchange appointmentExchange() {
        return new TopicExchange(RabbitTopology.APPOINTMENT_EXCHANGE, true, false);
    }

    @Bean
    public Queue doctorCommandQueue() {
        return new Queue(RabbitTopology.DOCTOR_COMMAND_QUEUE, true);
    }

    @Bean
    public Queue slotCommandQueue() {
        return new Queue(RabbitTopology.SLOT_COMMAND_QUEUE, true);
    }

    @Bean
    public Queue appointmentReplyQueue() {
        return new Queue(RabbitTopology.APPOINTMENT_REPLY_QUEUE, true);
    }

    @Bean
    public Declarables appointmentBindings(
            TopicExchange appointmentExchange,
            Queue doctorCommandQueue,
            Queue slotCommandQueue,
            Queue appointmentReplyQueue) {
        return new Declarables(
                BindingBuilder.bind(doctorCommandQueue)
                        .to(appointmentExchange)
                        .with(RabbitTopology.DOCTOR_COMMAND_ROUTING_PATTERN),
                BindingBuilder.bind(slotCommandQueue)
                        .to(appointmentExchange)
                        .with(RabbitTopology.SLOT_COMMAND_ROUTING_PATTERN),
                BindingBuilder.bind(appointmentReplyQueue)
                        .to(appointmentExchange)
                        .with(RabbitTopology.APPOINTMENT_REPLY_ROUTING_PATTERN)
        );
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
