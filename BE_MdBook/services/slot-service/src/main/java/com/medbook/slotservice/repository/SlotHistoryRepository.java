package com.medbook.slotservice.repository;

import com.medbook.slotservice.entity.SlotHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SlotHistoryRepository extends JpaRepository<SlotHistory, Long> {
    List<SlotHistory> findBySlotIdOrderByChangedAtDesc(Long slotId);
}
