package com.medbook.slotservice.entity;

import com.medbook.slotservice.entity.enums.EquipmentStatus;
import com.medbook.slotservice.entity.enums.EquipmentType;
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
        name = "equipments",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_equipment_facility_code",
                columnNames = {"facility_id", "equipment_code"}),
        indexes = {
            @Index(name = "idx_equipment_facility_room", columnList = "facility_id, room_id"),
            @Index(name = "idx_equipment_room_type", columnList = "room_id, equipment_type"),
            @Index(name = "idx_equipment_room_status", columnList = "room_id, status")
        })
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Equipment {

    @Id
    @Column(name = "id", nullable = false, length = 64)
    private String id;

    @Column(name = "equipment_code", nullable = false, length = 64)
    private String equipmentCode;

    @Column(name = "equipment_name", nullable = false, length = 255)
    private String equipmentName;

    @Column(name = "facility_id", nullable = false)
    private Long facilityId;

    @Column(name = "room_id", nullable = false, length = 64)
    private String roomId;

    @Enumerated(EnumType.STRING)
    @Column(name = "equipment_type", nullable = false, length = 40)
    private EquipmentType equipmentType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private EquipmentStatus status = EquipmentStatus.ACTIVE;

    @Column(name = "notes", length = 255)
    private String notes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
