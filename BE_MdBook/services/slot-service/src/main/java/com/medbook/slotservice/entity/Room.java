package com.medbook.slotservice.entity;

import com.medbook.slotservice.entity.enums.RoomCategory;
import com.medbook.slotservice.entity.enums.RoomStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(
        name = "rooms",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_room_facility_code",
                columnNames = {"facility_id", "room_code"}),
        indexes = {
            @Index(name = "idx_room_facility_category", columnList = "facility_id, room_category"),
            @Index(name = "idx_room_facility_status", columnList = "facility_id, status")
        })
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Room {

    @Id
    @Column(name = "id", nullable = false, length = 64)
    private String id;

    @Column(name = "room_code", nullable = false, length = 64)
    private String roomCode;

    @Column(name = "room_name", nullable = false, length = 255)
    private String roomName;

    @Column(name = "facility_id", nullable = false)
    private Long facilityId;

    @Enumerated(EnumType.STRING)
    @Column(name = "room_category", nullable = false, length = 40)
    private RoomCategory roomCategory;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private RoomStatus status = RoomStatus.ACTIVE;

    @Column(name = "notes", length = 255)
    private String notes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
