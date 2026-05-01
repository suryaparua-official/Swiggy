# Architecture Documentation

## Overview

Swiggy is built as a distributed microservices application deployed on Google Kubernetes Engine. This document describes the system design decisions and architecture.

## Microservices Design

### Why Microservices?

Each service is independently deployable, scalable, and maintainable. A failure in the Rider service does not affect the Auth service.

| Service    | Responsibility                             | Database            |
| ---------- | ------------------------------------------ | ------------------- |
| Auth       | Authentication, JWT tokens                 | MongoDB (users)     |
| Restaurant | Restaurants, menu, cart, orders, addresses | MongoDB (shared)    |
| Utils      | Image upload, payment processing           | Stateless           |
| Realtime   | WebSocket connections                      | In-memory           |
| Rider      | Rider profiles, order delivery             | MongoDB (shared)    |
| Admin      | Platform verification                      | MongoDB (read-only) |

### Inter-Service Communication

Two patterns are used:

**Synchronous (HTTP REST):**

- Services call each other directly via Kubernetes Service DNS
- Example: Utils calls Restaurant to get order amount before payment
- Example: Rider calls Restaurant to assign rider to order

**Asynchronous (RabbitMQ):**

- Used when one service needs to notify another without waiting
- Example: Utils publishes `PAYMENT_SUCCESS` → Restaurant consumes and updates order
- Example: Restaurant publishes `ORDER_READY_FOR_RIDER` → Rider consumes and notifies nearby riders

### Message Queue Design

```
Queue: payment_event
  Publisher: utils (after payment verified)
  Consumer: restaurant (updates order to "paid")

Queue: order_ready_queue
  Publisher: restaurant (when status = ready_for_rider)
  Consumer: rider (finds nearby riders, sends notifications)
```

All queues are `durable: true` — messages survive RabbitMQ restarts.

## Data Flow: Order Placement

```
1. Customer adds items to cart
   POST /api/cart/add → restaurant-service

2. Customer creates order
   POST /api/order/new → restaurant-service
   - Validates cart, restaurant, address
   - Calculates distance (Haversine formula)
   - Calculates fees (delivery + platform)
   - Creates order with status="pending", expiresAt=15min
   - Clears cart

3. Customer initiates payment
   POST /api/payment/create/razorpay → utils-service
   - utils calls restaurant: GET /api/order/:id (internal)
   - Creates Razorpay order
   - Returns razorpayOrderId to frontend

4. Customer completes payment (Razorpay popup)
   POST /api/payment/verify/razorpay → utils-service
   - Verifies HMAC signature (cryptographic proof)
   - Publishes to payment_event queue: { type: "PAYMENT_SUCCESS", orderId }

5. Restaurant service processes payment event
   - Updates order: paymentStatus="paid", removes expiresAt
   - Calls realtime-service: POST /api/v1/internal/emit
     { event: "order:new", room: "restaurant:ID" }

6. Restaurant owner sees new order (real-time)
   - Accepts → status="accepted"
   - Preparing → status="preparing"
   - Ready → status="ready_for_rider"
     Publishes to order_ready_queue

7. Rider service processes order_ready event
   - MongoDB geospatial query: find riders within 500m
   - For each rider: calls realtime-service to send notification

8. Rider accepts order
   - POST /api/rider/accept → rider-service
   - rider-service calls restaurant-service to assign rider (atomic update)
   - Realtime notification to customer and restaurant

9. Rider updates status
   - picked_up → delivered
   - Real-time updates to customer throughout
```

## Geospatial Architecture

Restaurant locations are stored as GeoJSON Points:

```json
{
  "autoLocation": {
    "type": "Point",
    "coordinates": [longitude, latitude]
  }
}
```

MongoDB 2dsphere index enables efficient geospatial queries:

```javascript
// Find restaurants within 5km of user
Restaurant.aggregate([
  {
    $geoNear: {
      near: { type: "Point", coordinates: [lng, lat] },
      maxDistance: 5000,
      spherical: true,
      query: { isVerified: true },
    },
  },
]);

// Find riders within 500m of restaurant
Rider.find({
  isAvailble: true,
  location: { $near: { $geometry: restaurantLocation, $maxDistance: 500 } },
});
```

## Security Architecture

### Authentication Flow

```
User → Google OAuth → Authorization Code
Frontend → Auth Service: POST /api/auth/login { code }
Auth Service → Google: Exchange code for tokens
Auth Service → Google: Get user info
Auth Service → MongoDB: Find or create user
Auth Service → Frontend: JWT token (15 days)

Future requests:
Frontend → Service: Authorization: Bearer <JWT>
Service middleware → Verify JWT → Attach user to request
```

### Internal Service Security

Services communicate internally using a shared secret:

```
Service A → Service B: x-internal-key: <INTERNAL_SERVICE_KEY>
Service B middleware → Verify key matches env variable
```

This prevents external callers from accessing internal endpoints.

### Workload Identity Federation

GitHub Actions authenticates to GCP without storing any credentials:

```
GitHub Actions runs
  → Requests OIDC token from GitHub
  → Sends token to GCP STS
  → GCP verifies: token is from github.com/suryaparua-official/Swiggy
  → GCP returns short-lived access token
  → GitHub Actions uses token to deploy to GKE
```

## Scalability Design

### Horizontal Pod Autoscaling

Each deployment can be scaled independently based on load.

### Node Autoscaling

GKE node pool scales from 1 to 4 nodes automatically based on pod resource requests.

### Stateless Services

All backend services are stateless — session data is in JWT tokens, not server memory. Any pod can handle any request.

### Socket.io Limitation

The current Realtime service runs as a single replica. For production with multiple replicas, Socket.io needs Redis adapter for cross-pod pub/sub.

## Observability Stack

```
Application Pods
    │ metrics
    ▼
Prometheus ──► Alertmanager ──► Slack
    │
    ▼
Grafana (dashboards)

Application Pods
    │ stdout/stderr logs
    ▼
Promtail (per node DaemonSet)
    │
    ▼
Loki ──► Grafana (log explorer)

Application Pods (future)
    │ traces via OTEL SDK
    ▼
OpenTelemetry Collector
    │
    ▼
Jaeger (trace UI)
```
