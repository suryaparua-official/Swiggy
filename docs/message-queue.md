# Message Queue & Event Architecture

RabbitMQ-based event-driven architecture for order processing and notifications.

---

## Overview

Swiggy uses **RabbitMQ** as the message broker for asynchronous communication between microservices. This enables:

- Loose coupling between services
- Reliable message delivery with acknowledgments
- Event-driven order processing pipeline
- Scalable notification system

---

## RabbitMQ Configuration

**Connection Details:**

- **Host:** `rabbitmq` (Docker) or `localhost`
- **Port:** `5672` (AMQP), `15672` (Management UI)
- **Default Credentials:** `guest:guest`
- **Management UI:** http://localhost:15672

---

## Exchanges

### Exchange Types

**1. Orders Exchange (Direct)**

- **Name:** `orders-exchange`
- **Type:** `direct`
- **Durable:** Yes
- **Purpose:** Route order events to specific queues based on routing key

**2. Payments Exchange (Direct)**

- **Name:** `payments-exchange`
- **Type:** `direct`
- **Durable:** Yes
- **Purpose:** Handle payment processing events

**3. Notifications Exchange (Topic)**

- **Name:** `notifications-exchange`
- **Type:** `topic`
- **Durable:** Yes
- **Purpose:** Broadcast notifications to multiple subscribers

---

## Queues

### Order Processing Queues

#### 1. Order Creation Queue

- **Name:** `orders-queue`
- **Routing Key:** `order.created`
- **Consumers:** Restaurant Service
- **Purpose:** Notify restaurants of new orders
- **TTL:** 1 hour
- **Dead Letter Exchange:** `orders-dlx`

```javascript
// Message format
{
  type: "order.created",
  orderId: "ORD-2024-001",
  restaurantId: "rest_123",
  customerId: "user_456",
  items: [...],
  totalAmount: 1299,
  deliveryAddress: {...},
  timestamp: 1704067200000,
  retryCount: 0
}
```

#### 2. Payment Processing Queue

- **Name:** `payment-queue`
- **Routing Key:** `payment.process`
- **Consumers:** Utils Service
- **Purpose:** Process payment transactions
- **TTL:** 30 minutes

```javascript
{
  type: "payment.process",
  orderId: "ORD-2024-001",
  userId: "user_456",
  amount: 1299,
  currency: "INR",
  paymentMethod: "razorpay",
  timestamp: 1704067200000
}
```

#### 3. Order Ready Queue

- **Name:** `order-ready-queue`
- **Routing Key:** `order.ready`
- **Consumers:** Rider Service
- **Purpose:** Notify available riders that order is ready for pickup
- **TTL:** 2 hours

```javascript
{
  type: "order.ready",
  orderId: "ORD-2024-001",
  restaurantId: "rest_123",
  pickupLocation: { lat: 40.7128, lng: -74.0060 },
  deliveryLocation: { lat: 40.7589, lng: -73.9851 },
  estimatedDistance: 5.2,
  estimatedTime: 25, // minutes
  customerPhone: "+1234567890",
  timestamp: 1704067200000
}
```

#### 4. Delivery Status Queue

- **Name:** `delivery-status-queue`
- **Routing Key:** `delivery.status.*`
- **Consumers:** Frontend (via WebSocket), Orders Service
- **Purpose:** Update delivery status in real-time

```javascript
{
  type: "delivery.status.updated",
  orderId: "ORD-2024-001",
  riderId: "rider_789",
  status: "picked_up",
  location: { lat: 40.72, lng: -74.00 },
  eta: 18,
  timestamp: 1704067200000
}
```

---

## Routing Keys

| Key Pattern           | Description                   | Producer           | Consumer           |
| --------------------- | ----------------------------- | ------------------ | ------------------ |
| `order.created`       | New order placed              | Restaurant Service | Rider Service      |
| `order.confirmed`     | Order confirmed by restaurant | Restaurant Service | Frontend           |
| `order.preparing`     | Restaurant started preparing  | Restaurant Service | Frontend           |
| `order.ready`         | Order ready for pickup        | Restaurant Service | Rider Service      |
| `payment.process`     | Payment needs processing      | Restaurant Service | Utils Service      |
| `payment.success`     | Payment completed             | Utils Service      | Restaurant Service |
| `payment.failed`      | Payment failed                | Utils Service      | Restaurant Service |
| `delivery.accepted`   | Rider accepted delivery       | Rider Service      | Frontend           |
| `delivery.picked_up`  | Rider picked up order         | Rider Service      | Frontend           |
| `delivery.in_transit` | Order in transit              | Rider Service      | Frontend           |
| `delivery.delivered`  | Order delivered               | Rider Service      | Frontend           |

---

## Dead Letter Exchange (DLX)

- **Name:** `orders-dlx`
- **Purpose:** Handle messages that fail processing
- **Retry Logic:**
  1. First attempt: Immediate
  2. Retry 1: After 5 minutes
  3. Retry 2: After 15 minutes
  4. Retry 3: After 1 hour
  5. After 3 retries → Move to DLQ (Dead Letter Queue)

```javascript
// DLX Message (after max retries)
{
  ...originalMessage,
  retryCount: 3,
  lastError: "Service timeout",
  dlqTime: 1704067200000,
  action: "manual_review_required"
}
```

---

## Service Integration Points

### Restaurant Service (Producer & Consumer)

**Produces:**

- `order.confirmed`
- `order.preparing`
- `order.ready`
- `payment.success`
- `payment.failed`

**Consumes:**

- `order.created` → Order notification
- `payment.process` request

### Rider Service (Producer & Consumer)

**Produces:**

- `delivery.accepted`
- `delivery.picked_up`
- `delivery.in_transit`
- `delivery.delivered`

**Consumes:**

- `order.ready` → Available deliveries

### Utils Service (Payment Handler)

**Produces:**

- `payment.success`
- `payment.failed`
- `refund.initiated`

**Consumes:**

- `payment.process` → Process Razorpay payment

### Realtime Service (WebSocket Bridge)

**Consumes:**

- `order.confirmed`
- `order.preparing`
- `order.ready`
- `delivery.*`

**Action:** Broadcasts to connected clients via WebSocket

---

## Message Flow Diagram

```
Customer Places Order
        ↓
Restaurant Service receives order
        ↓
Publishes: order.created → Order Queue
        ↓
Restaurant Service (Consumer)
  - Stores order in DB
  - Updates restaurant dashboard
  - Publishes: order.confirmed
        ↓
Realtime Service consumes order.confirmed
  - Broadcasts to customer via WebSocket
        ↓
Restaurant prepares food
  - Updates order status in DB
  - Publishes: order.ready
        ↓
Rider Service consumes order.ready
  - Notifies available riders
  - Rider accepts delivery
  - Publishes: delivery.accepted
        ↓
Rider picks up order
  - Publishes: delivery.picked_up
  - Realtime broadcasts to customer
        ↓
Rider delivers order
  - Publishes: delivery.delivered
  - Order marked complete
```

---

## Error Handling

### Retry Strategy

```javascript
function handleMessageWithRetry(message, maxRetries = 3) {
  try {
    processMessage(message);
    channel.ack(message);
  } catch (error) {
    message.retryCount++;
    if (message.retryCount < maxRetries) {
      // Re-queue with delay
      const delay = Math.pow(2, message.retryCount) * 1000; // Exponential backoff
      setTimeout(() => channel.nack(message, true), delay);
    } else {
      // Send to DLX
      channel.nack(message, false);
    }
  }
}
```

### Dead Letter Handling

- Failed messages moved to DLQ after max retries
- Manual review process required
- Logged for debugging and alerting

---

## Monitoring & Troubleshooting

### Check Queue Status

```bash
# Via RabbitMQ CLI
rabbitmqctl list_queues name consumers messages_ready messages_unacknowledged

# Via Management UI
http://localhost:15672/#/queues
```

### Common Issues

**1. Queue Growing (Consumer Lag)**

- Check consumer service logs
- Verify consumer is running
- Scale up consumer replicas

**2. Messages Not Being Consumed**

- Verify routing keys match
- Check consumer bindings
- Ensure consumer service is healthy

**3. Message Delivery Timeout**

- Increase consumer timeout
- Check network connectivity
- Review service logs for slow processing

### Health Check Endpoint

```bash
GET http://localhost:5001/health/rabbitmq
```

Response:

```json
{
  "status": "healthy",
  "connected": true,
  "queuesMonitored": 4,
  "messagesInQueues": {
    "orders-queue": 0,
    "payment-queue": 2,
    "order-ready-queue": 0
  }
}
```

---

## Configuration (docker-compose.yml)

```yaml
rabbitmq:
  image: rabbitmq:3.13-management-alpine
  environment:
    RABBITMQ_DEFAULT_USER: guest
    RABBITMQ_DEFAULT_PASS: guest
  ports:
    - "5672:5672" # AMQP
    - "15672:15672" # Management UI
  volumes:
    - rabbitmq_data:/var/lib/rabbitmq
  healthcheck:
    test: rabbitmq-diagnostics -q ping
    interval: 30s
    timeout: 10s
    retries: 5
```

---

## Best Practices

1. **Idempotency:** Ensure services can handle duplicate messages
2. **Message Headers:** Include traceId for distributed tracing
3. **Timeout:** Set appropriate consumer timeouts based on processing time
4. **Logging:** Log all published and consumed messages for audit trail
5. **Testing:** Use RabbitMQ test container for integration tests
6. **Circuit Breaker:** Implement circuit breaker for failing services
7. **TTL & DLX:** Always configure TTL and DLX for queues
8. **Monitoring:** Set up alerts for queue depth and consumer lag

---

## Testing Message Flows

### Using RabbitMQ Management UI

1. Navigate to http://localhost:15672
2. Go to **Queues** tab
3. Click on queue name
4. Publish test message in **Publish message** section

### Programmatic Testing

```javascript
const amqp = require("amqplib");

async function publishTestMessage() {
  const connection = await amqp.connect("amqp://localhost");
  const channel = await connection.createChannel();

  const message = {
    type: "order.created",
    orderId: "TEST-001",
    timestamp: Date.now(),
  };

  await channel.assertExchange("orders-exchange", "direct", { durable: true });
  await channel.publish(
    "orders-exchange",
    "order.created",
    Buffer.from(JSON.stringify(message)),
    { persistent: true, contentType: "application/json" },
  );

  console.log("Test message published");
  await channel.close();
  await connection.close();
}

publishTestMessage().catch(console.error);
```
