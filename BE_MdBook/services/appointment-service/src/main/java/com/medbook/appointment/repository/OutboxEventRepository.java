package com.medbook.appointment.repository;

import com.medbook.appointment.entity.OutboxEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OutboxEventRepository extends JpaRepository<OutboxEvent, String> {
    List<OutboxEvent> findByPublished(Boolean published);
    List<OutboxEvent> findTop50ByPublishedFalseOrderByCreatedAtAsc();
    List<OutboxEvent> findByAggregateId(String aggregateId);
}
