# Service Architecture & Guides

Detailed guides for each microservice in Swiggy.

---

## Table of Contents

- [Auth Service](#auth-service)
- [Restaurant Service](#restaurant-service)
- [Rider Service](#rider-service)
- [Utils Service (Payment)](#utils-service-payment)
- [Admin Service](#admin-service)
- [Realtime Service](#realtime-service)

---

## Auth Service

**Port:** 5000  
**Technology:** Express.js, MongoDB, JWT, Google OAuth  
**Responsibility:** User authentication, token management, role-based access

### Directory Structure

```
services/auth/
├── src/
│   ├── config/
│   │   ├── db.ts          # MongoDB connection
│   │   └── googleConfig.ts # OAuth configuration
│   ├── controllers/
│   │   └── auth.ts        # Auth logic
│   ├── middlewares/
│   │   ├── isAuth.ts      # JWT verification
│   │   └── trycatch.ts    # Error handling
│   ├── model/
│   │   └── User.ts        # User schema
│   ├── routes/
│   │   └── auth.ts        # Auth routes
│   └── index.ts           # Server startup
├── .env
├── Dockerfile
└── package.json
```

### Key Endpoints

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - Email/password login
- `POST /api/auth/google` - Google OAuth login
- `GET /api/auth/verify` - Verify JWT token
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - Invalidate token

### Database Models

**User Schema:**

```typescript
{
  email: string (unique)
  password: string (hashed with bcrypt)
  name: string
  phone: string
  role: 'customer' | 'restaurant' | 'rider' | 'admin'
  profileImage: string
  isVerified: boolean
  googleId: string (optional)
  createdAt: Date
  updatedAt: Date
}
```

### Authentication Flow

```
User Registration/Login
    ↓
Validate credentials
    ↓
Generate JWT token
    ↓
Return token to client
    ↓
Client stores in localStorage
    ↓
Include in Authorization header for subsequent requests
    ↓
Auth middleware verifies token
```

### Common Issues & Solutions

**1. JWT Token Expired**

```
Error: Token expired
Solution: Use refresh token endpoint or re-login
```

**2. Google OAuth Not Working**

```
Check GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env
Verify redirect URI in Google Cloud Console matches backend URL
```

### Development

```bash
cd services/auth
npm install
npm run dev

# Test endpoints
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","name":"Test User","role":"customer"}'
```

---

## Restaurant Service

**Port:** 5001  
**Technology:** Express.js, MongoDB, RabbitMQ, Multer (file upload)  
**Responsibility:** Restaurant management, menu, orders, RabbitMQ integration

### Directory Structure

```
services/restaurant/
├── src/
│   ├── config/
│   │   ├── db.ts              # MongoDB
│   │   ├── datauri.ts         # File upload config
│   │   ├── rabbitmq.ts        # RabbitMQ connection
│   │   ├── order.publisher.ts # Publish orders
│   │   └── payment.consumer.ts # Consume payments
│   ├── controllers/
│   │   ├── restaurant.ts
│   │   ├── menu-item.ts
│   │   ├── order.ts
│   │   ├── cart.ts
│   │   └── address.ts
│   ├── models/
│   │   ├── Restaurant.ts
│   │   ├── MenuItems.ts
│   │   ├── Order.ts
│   │   ├── Cart.ts
│   │   └── Address.ts
│   ├── routes/
│   ├── middlewares/
│   │   ├── multer.ts          # File upload
│   │   └── isAuth.ts
│   └── index.ts
├── .env
├── Dockerfile
└── package.json
```

### Key Endpoints

**Restaurants:**

- `GET /api/restaurant` - List all with location-based search
- `POST /api/restaurant` - Create new (owner only)
- `PUT /api/restaurant/:id` - Update (owner only)

**Menu Items:**

- `GET /api/restaurant/:restaurantId/menu`
- `POST /api/restaurant/:restaurantId/menu` - Add item
- `PUT /api/restaurant/:restaurantId/menu/:itemId` - Update item
- `DELETE /api/restaurant/:restaurantId/menu/:itemId` - Delete item

**Orders:**

- `POST /api/restaurant/order` - Create order
- `GET /api/restaurant/orders` - Get restaurant's orders
- `PUT /api/restaurant/order/:orderId/status` - Update status

### Order Processing Flow

```
Customer → Creates Order
    ↓
Restaurant Service → Validates & saves to DB
    ↓
Publishes "order.created" to RabbitMQ
    ↓
Sends notification to restaurant
    ↓
Restaurant confirms order (manually or auto)
    ↓
Publishes "order.confirmed"
    ↓
Chef starts preparing
    ↓
When ready: Publishes "order.ready"
    ↓
RabbitMQ consumers notify riders
```

### RabbitMQ Integration

**Publishing Orders:**

```typescript
// In order.controller.ts
const channel = await getRabbitMQChannel();
await channel.publish(
  "orders-exchange",
  "order.created",
  Buffer.from(JSON.stringify(orderData)),
  { persistent: true },
);
```

**Consuming Payment Events:**

```typescript
// In payment.consumer.ts
const channel = await getRabbitMQChannel();
await channel.consume("payment-queue", async (msg) => {
  const payment = JSON.parse(msg.content.toString());
  await Order.findByIdAndUpdate(payment.orderId, {
    paymentStatus: "completed",
  });
  channel.ack(msg);
});
```

### File Upload (Cloudinary)

```typescript
// Image upload for restaurant profile, menu items
const multer = require("multer");
const upload = multer({ storage: multerStorage });

router.post(
  "/api/restaurant/:id/image",
  authenticateToken,
  upload.single("image"),
  uploadRestaurantImage,
);
```

### Development

```bash
cd services/restaurant
npm install
npm run dev

# Requires MongoDB and RabbitMQ running
```

---

## Rider Service

**Port:** 5005  
**Technology:** Express.js, MongoDB, RabbitMQ, Geolocation  
**Responsibility:** Rider profiles, order delivery, location tracking

### Directory Structure

```
services/rider/
├── src/
│   ├── config/
│   │   ├── db.ts
│   │   ├── rabbitmq.ts
│   │   └── orderReady.consumer.ts
│   ├── controllers/
│   │   └── rider.ts
│   ├── model/
│   │   └── Rider.ts
│   ├── routes/
│   │   └── rider.ts
│   ├── middlewares/
│   │   ├── multer.ts
│   │   └── isAuth.ts
│   └── index.ts
├── .env
├── Dockerfile
└── package.json
```

### Key Endpoints

- `POST /api/rider` - Create rider profile
- `GET /api/rider` - Get rider profile
- `PUT /api/rider/status` - Update online status
- `GET /api/rider/available-orders` - Get nearby orders
- `POST /api/rider/order/:orderId/accept` - Accept order
- `PUT /api/rider/order/:orderId/status` - Update delivery status

### Rider Workflow

```
Rider Registers
    ↓
Creates profile (vehicle, license, etc.)
    ↓
Admin verifies
    ↓
Rider goes online
    ↓
Receives order.ready events from RabbitMQ
    ↓
Can see available orders based on location
    ↓
Accepts order
    ↓
Picks up from restaurant
    ↓
Updates delivery status (picked_up → in_transit → delivered)
    ↓
Location tracked in real-time via WebSocket
```

### Location Tracking

```typescript
// Update current location
router.put("/api/rider/status", async (req, res) => {
  const { isOnline, currentLocation } = req.body;

  await Rider.findByIdAndUpdate(req.user.riderId, {
    isOnline,
    "currentLocation.lat": currentLocation.lat,
    "currentLocation.lng": currentLocation.lng,
    "currentLocation.updatedAt": new Date(),
  });

  // Emit location update to WebSocket
  io.to(`order-${orderId}`).emit("rider-location", {
    riderId: req.user.riderId,
    lat: currentLocation.lat,
    lng: currentLocation.lng,
  });
});
```

### Finding Nearby Orders

```typescript
// Use MongoDB geospatial query
const nearbyOrders = await Order.find({
  "deliveryAddress.location": {
    $near: {
      $geometry: { type: "Point", coordinates: [lng, lat] },
      $maxDistance: 5000, // 5km
    },
  },
  orderStatus: "ready",
  riderId: null,
});
```

---

## Utils Service (Payment)

**Port:** 5002  
**Technology:** Express.js, RabbitMQ, Razorpay API, Cloudinary  
**Responsibility:** Payment processing, image uploads, external API integration

### Directory Structure

```
services/utils/
├── src/
│   ├── config/
│   │   ├── payment.producer.ts
│   │   ├── rabbitmq.ts
│   │   ├── razorpay.ts
│   │   └── verifyRazorpay.ts
│   ├── controllers/
│   │   ├── payment.ts
│   │   └── cloudinary.ts
│   ├── routes/
│   │   ├── payment.ts
│   │   └── cloudinary.ts
│   └── index.ts
├── .env
├── Dockerfile
└── package.json
```

### Key Endpoints

- `POST /api/payment/create-order` - Create Razorpay order
- `POST /api/payment/verify` - Verify payment signature
- `POST /api/cloudinary/upload` - Upload image to Cloudinary

### Payment Flow

```
Frontend requests payment
    ↓
Backend creates Razorpay order
    ↓
Frontend opens Razorpay modal
    ↓
User enters payment details
    ↓
Razorpay returns payment ID
    ↓
Frontend sends verification request
    ↓
Backend verifies signature
    ↓
Publishes payment.success to RabbitMQ
    ↓
Restaurant Service updates order
```

### Razorpay Integration

```typescript
// Create order
const razorpayOrder = await razorpay.orders.create({
  amount: totalAmount * 100, // In paise
  currency: "INR",
  receipt: orderId,
});

// Verify signature
const signature = crypto
  .createHmac("sha256", RAZORPAY_SECRET)
  .update(`${orderId}|${paymentId}`)
  .digest("hex");

if (signature !== providedSignature) {
  throw new Error("Invalid signature");
}
```

### File Upload to Cloudinary

```typescript
// Multer setup for file upload
const upload = multer({ storage: memoryStorage });

router.post(
  "/api/cloudinary/upload",
  authenticate,
  upload.single("file"),
  async (req, res) => {
    const result = await cloudinary.uploader.upload(
      `data:${req.file.mimetype};base64,${req.file.buffer.toString("base64")}`,
    );
    res.json({ url: result.secure_url });
  },
);
```

---

## Admin Service

**Port:** 5003  
**Technology:** Express.js, MongoDB  
**Responsibility:** Restaurant & rider verification, statistics, moderation

### Key Endpoints

- `GET /api/admin/pending` - Get pending verifications
- `POST /api/admin/restaurant/:id/approve` - Approve restaurant
- `POST /api/admin/restaurant/:id/reject` - Reject restaurant
- `POST /api/admin/rider/:id/approve` - Approve rider
- `POST /api/admin/rider/:id/reject` - Reject rider
- `GET /api/admin/statistics` - Get platform statistics

### Verification Workflow

```
Restaurant/Rider Registration
    ↓
Application marked "pending"
    ↓
Admin reviews documents
    ↓
Admin approves or rejects
    ↓
Notification sent to applicant
    ↓
If approved: Access granted to features
```

---

## Realtime Service

**Port:** 5004  
**Technology:** Socket.io, Node.js  
**Responsibility:** WebSocket connections, order updates, location tracking, notifications

### Directory Structure

```
services/realtime/
├── src/
│   ├── socket.ts      # Socket event handlers
│   ├── routes/
│   │   └── internal.ts # Internal endpoints
│   └── index.ts
├── .env
├── Dockerfile
└── package.json
```

### Key Socket Events

**Joining/Leaving Orders:**

```typescript
socket.on("join-order", ({ orderId }) => {
  socket.join(`order-${orderId}`);
});

socket.on("leave-order", ({ orderId }) => {
  socket.leave(`order-${orderId}`);
});
```

**Broadcasting Updates:**

```typescript
io.to(`order-${orderId}`).emit("order-updated", {
  orderId,
  status: "confirmed",
  timestamp: Date.now(),
});

io.to(`order-${orderId}`).emit("rider-location", {
  riderId,
  lat,
  lng,
  eta: 15,
});
```

**Notifications:**

```typescript
// Send to specific user
io.to(`user-${userId}`).emit("notification", {
  type: "order-ready",
  message: "Your order is ready for pickup",
});
```

### Connection Authentication

```typescript
io.use((socket, next) => {
  const token = socket.handshake.auth.token;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    socket.userId = decoded.id;
    next();
  } catch (err) {
    next(new Error("Authentication failed"));
  }
});
```

---

## Service Communication Matrix

| From       | To         | Method    | Purpose                  |
| ---------- | ---------- | --------- | ------------------------ |
| Restaurant | RabbitMQ   | Publish   | Send order events        |
| Rider      | RabbitMQ   | Consume   | Receive available orders |
| Utils      | RabbitMQ   | Publish   | Send payment status      |
| Restaurant | RabbitMQ   | Consume   | Receive payment status   |
| All        | Realtime   | WebSocket | Broadcast updates        |
| Frontend   | Auth       | REST      | Authentication           |
| Frontend   | Restaurant | REST      | Browse, order            |
| Frontend   | Rider      | REST      | Accept deliveries        |
| Frontend   | Realtime   | WebSocket | Real-time updates        |

---

## Development Setup for Multiple Services

```bash
# Terminal 1 - Auth
cd services/auth && npm run dev

# Terminal 2 - Restaurant
cd services/restaurant && npm run dev

# Terminal 3 - Rider
cd services/rider && npm run dev

# Terminal 4 - Utils
cd services/utils && npm run dev

# Terminal 5 - Realtime
cd services/realtime && npm run dev

# Terminal 6 - Frontend
cd frontend && npm run dev

# Terminal 7 - Database & Message Queue
docker-compose up
```

---

## Environment Variables by Service

All services require standard variables + service-specific ones in `.env` file. See individual `.env.example` in each service directory.

---

## Common Service Issues

1. **Service can't connect to MongoDB:**
   - Verify MONGODB_URI is correct
   - Ensure MongoDB is running
   - Check network connectivity

2. **RabbitMQ connection fails:**
   - Verify RABBITMQ_URL is correct
   - Ensure RabbitMQ is running and accessible
   - Check credentials (default: guest:guest)

3. **JWT token verification fails:**
   - Ensure JWT_SECRET is same across all services
   - Check token expiration

4. **CORS errors:**
   - Verify CORS headers in Express app
   - Check allowed origins in configuration
