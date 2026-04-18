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
| **Notification**| 5005 | `/notification`| MongoDB (`notification_db`) | Listens to `notification-delivery` queue; sends Brevo emails. |
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

### 🔔 Offline Notifications (Notification Service)
- **Integration**: RabbitMQ.
- **Queue**: `notification-delivery`.
- **Logic**: If a recipient is not currently connected to the socket, send a JSON payload to the queue to trigger a push/email notification.

---

## 4. 📝 Development Guidelines
1. **Health Check**: Service must return `{"status": "ok"}` at `GET /chat/health`.
2. **Logging**: Include `Correlation-ID` in all logs to trace requests through the Gateway.
3. **Container**: Provide a `Dockerfile` and update `docker-compose.yml` to include the `chat-service` and its `mongodb` dependency.
