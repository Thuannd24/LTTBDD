package com.medbook.appointment.repository;

import com.medbook.appointment.entity.InboxMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface InboxMessageRepository extends JpaRepository<InboxMessage, String> {
    Optional<InboxMessage> findByMessageId(String messageId);
    java.util.List<InboxMessage> findByProcessed(Boolean processed);
}
