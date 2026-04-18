package com.medbook.doctor.repository;

import com.medbook.doctor.entity.InboxMessage;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InboxMessageRepository extends JpaRepository<InboxMessage, String> {
    Optional<InboxMessage> findByMessageId(String messageId);
}
