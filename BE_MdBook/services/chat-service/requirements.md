# 📚 MedBook System & Chat Service - Comprehensive Requirements Guide

This document provides an exhaustive overview of the MedBook Microservices ecosystem and the specific requirements for the new Chat Service. Use this as the single source of truth for implementation.

---

## 1. 🌐 System Architecture & Service Catalog

MedBook is built with **Spring Boot 3.x** and **Spring Cloud**. Every service registers with **Eureka** and is secured via **Keycloak**.

### 🛠️ Infrastructure Services
| Service | Port | Description |
| :--- | :--- | :--- |
| **API Gateway** | 8080 | Single entry point. Handles JWT validation and routing. |
| **Eureka Server**| 8761 | Service Registry & Discovery. |
| **Keycloak** | 8181 | Identity Provider (OpenID Connect). Realm: `clinic-realm`. |

### ⚙️ Business Microservices
| Service | Port | Context | Database | Core Responsibility |
| :--- | :--- | :--- | :--- | :--- |
| **Identity** | 5001 | `/identity` | Postgres (`identity_db`) | Auth, Token Introspection, User/Role management. |
| **Doctor** | 5002 | `/` | Postgres (`doctor_db`) | Doctor catalog, specialties, status. |
| **Appointment**| 5003 | `/` | Postgres (`appointment_db`) | Booking logic, slots, RabbitMQ events. |
| **Facility** | 5004 | `/` | Postgres (`facility_db`) | Clinic & Hospital management. |
| **Chat** | **5006** | **/chat** | **MongoDB (`chat_db`)** | **Real-time messaging via Socket.IO.** |
| **MedicalRecord**| 5007 | `/` | MongoDB (`medical_record_db`) | Electronic Medical Records (EMR). |
| **Search** | 5008 | `/` | Elasticsearch | Advanced search for doctors/facilities. |
| **Review** | 5009 | `/` | Postgres (`review_db`) | Patient feedback and ratings. |
| **Profile** | 5010 | `/profile` | Postgres (`profile_db`) | Detailed User (Patient/Doctor) profiles. |

---

## 2. 💬 Chat Service: Core Requirements

### 💎 Real-time Communication
- **Protocol**: WebSockets via **Socket.IO** (using `netty-socketio`).
- **Path**: The socket should be accessible via `ws://localhost:8080/api/v1/chat`.
- **Scaling**: If deploying multiple replicas, use a Redis Pub/Sub adapter to sync events across nodes.

### 🔐 Security & Handshake
- **Handshake Auth**: Must intercept the Socket.IO connection request.
- **JWT Validation**: Verify the `token` param against Keycloak (`clinic-realm`).
- **Authorization**:
  - **Authority Prefix**: `ROLE_` (standard across MedBook).
  - **Roles Claim**: `roles` in the JWT payload.
- **Internal Verification**: Optionally call `identity-service`'s introspect endpoint for extra validation.

### 🗄️ Persistence (MongoDB)
- **Collection `conversations`**:
  - `participants`: List of User IDs.
  - `last_message`: Snippet of the last message.
  - `updated_at`: Timestamp for sorting.
- **Collection `messages`**:
  - `conversation_id`: Reference.
  - `sender_id`: UUID.
  - `content`: Text or Media URL.
  - `status`: `SENT`, `DELIVERED`, `READ`.

---

## 3. 🔗 Critical Integration Points

### 🚪 Gateway Routing
Update `gateway/src/main/resources/application.yml`:
```yaml
- id: chat-service
  uri: lb://CHAT-SERVICE
  predicates:
    - Path=/api/v1/chat/**
  filters:
    - RewritePath=/api/v1/chat/(?<segment>.*), /chat/${segment}
```

### 👤 User Information (Profile Service)
- **Dependency**: Use **OpenFeign**.
- **Endpoint**: `GET /profile/profiles/patients/by-user/{userId}`.
- **Goal**: Fetch names and avatars to display in the chat UI.

### 🔔 Notifications
- **Status**: Currently disabled (Notification Service removed).
- **Future Integration**: Re-implement event-driven messaging if a notification provider is added.

---

## 4. 🚀 Key Integration Steps for the Next Agent
1. **Handshake Auth**: Intercept Socket.IO handshake to validate JWT using Keycloak `issuer-uri`.
2. **Doctor Verification**: Before allowing a new conversation or message, verify doctor active status via Feign Client calling `doctor-service`.
3. **Metadata Aggregation**: Implement a helper to aggregate name, avatar, and titles from both `profile-service` and `doctor-service`.
4. **Remove Direct FCM**: Strip out `firebase-admin` logic (`firebase.js`) from the cloned source code.
5. **Event Flow**:
   - Save message to MongoDB.
   - Emit to recipient via Socket.IO if online.
   - Publish JSON payload to RabbitMQ (`notification-delivery`) if recipient is offline.ncy.
