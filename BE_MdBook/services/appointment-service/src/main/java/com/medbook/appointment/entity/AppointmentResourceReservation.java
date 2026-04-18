package com.medbook.appointment.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "appointment_resource_reservations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppointmentResourceReservation {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;
    
    @Column(nullable = false, length = 50)
    String appointmentId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "appointmentId", insertable = false, updatable = false)
    Appointment appointment;
    
    @Column(nullable = false, length = 50)
    String slotId;
    
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    ResourceTargetType targetType;
    
    @Column(nullable = false, length = 50)
    String targetId;
    
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    ReservationStatus status;
    
    public enum ResourceTargetType {
        DOCTOR, ROOM, EQUIPMENT
    }
    
    public enum ReservationStatus {
        RESERVED, RELEASED, FAILED
    }
}
