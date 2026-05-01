# API Reference

Complete API documentation for all Swiggy microservices.

---

## Table of Contents

- [Auth Service](#auth-service)
- [Restaurant Service](#restaurant-service)
- [Rider Service](#rider-service)
- [Utils Service (Payment)](#utils-service)
- [Admin Service](#admin-service)
- [Realtime Service](#realtime-service)

---

## Auth Service

**Base URL:** `http://localhost:5000` | **Port:** `5000`

### Endpoints

#### 1. Register User

```
POST /api/auth/register
```

**Request:**

```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "role": "customer" // "customer" | "restaurant" | "rider"
}
```

**Response:** `201 Created`

```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "customer"
  }
}
```

#### 2. Login

```
POST /api/auth/login
```

**Request:**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "role": "customer"
  }
}
```

#### 3. Google OAuth Login

```
POST /api/auth/google
```

**Request:**

```json
{
  "googleToken": "google_id_token"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "token": "jwt_token_here",
  "isNewUser": false
}
```

#### 4. Verify Token

```
GET /api/auth/verify
```

**Headers:** `Authorization: Bearer jwt_token_here`

**Response:** `200 OK`

```json
{
  "success": true,
  "user": { "id": "...", "email": "...", "role": "..." }
}
```

---

## Restaurant Service

**Base URL:** `http://localhost:5001` | **Port:** `5001`

### Restaurant Management

#### 1. Create Restaurant

```
POST /api/restaurant
```

**Headers:** `Authorization: Bearer token`

**Request:**

```json
{
  "name": "Pizza Palace",
  "description": "Authentic Italian Pizza",
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "zipcode": "10001",
    "lat": 40.7128,
    "lng": -74.006
  },
  "cuisine": ["Italian", "Pizza"],
  "phone": "555-1234",
  "rating": 4.5
}
```

**Response:** `201 Created`

#### 2. Get All Restaurants

```
GET /api/restaurant
```

**Query Params:**

- `latitude` (optional) - for location-based search
- `longitude` (optional)
- `radius` (optional) - in km

**Response:** `200 OK`

```json
{
  "success": true,
  "restaurants": [
    {
      "_id": "rest_id",
      "name": "Pizza Palace",
      "address": { ... },
      "cuisine": [...],
      "rating": 4.5,
      "distance": 2.5
    }
  ]
}
```

#### 3. Get Restaurant by ID

```
GET /api/restaurant/:id
```

#### 4. Update Restaurant

```
PUT /api/restaurant/:id
```

**Headers:** `Authorization: Bearer token` (Owner only)

#### 5. Delete Restaurant

```
DELETE /api/restaurant/:id
```

**Headers:** `Authorization: Bearer token` (Owner/Admin only)

---

### Menu Items

#### 1. Add Menu Item

```
POST /api/restaurant/:restaurantId/menu
```

**Headers:** `Authorization: Bearer token` (Restaurant owner only)

**Request:**

```json
{
  "name": "Margherita Pizza",
  "description": "Fresh mozzarella and basil",
  "price": 12.99,
  "category": "Pizza",
  "image": "image_url",
  "vegetarian": true,
  "vegan": false
}
```

**Response:** `201 Created`

#### 2. Get Menu Items

```
GET /api/restaurant/:restaurantId/menu
```

#### 3. Update Menu Item

```
PUT /api/restaurant/:restaurantId/menu/:itemId
```

#### 4. Delete Menu Item

```
DELETE /api/restaurant/:restaurantId/menu/:itemId
```

---

### Orders

#### 1. Create Order

```
POST /api/restaurant/order
```

**Headers:** `Authorization: Bearer token`

**Request:**

```json
{
  "restaurantId": "rest_id",
  "items": [
    {
      "menuItemId": "item_id",
      "quantity": 2
    }
  ],
  "deliveryAddress": {
    "street": "456 Oak Ave",
    "city": "New York",
    "zipcode": "10002"
  }
}
```

#### 2. Get Restaurant Orders

```
GET /api/restaurant/orders
```

**Headers:** `Authorization: Bearer token` (Restaurant owner)

#### 3. Update Order Status

```
PUT /api/restaurant/order/:orderId/status
```

**Headers:** `Authorization: Bearer token`

**Request:**

```json
{
  "status": "preparing" // "pending" | "preparing" | "ready" | "cancelled"
}
```

---

## Rider Service

**Base URL:** `http://localhost:5005` | **Port:** `5005`

### Profile Management

#### 1. Create Rider Profile

```
POST /api/rider
```

**Headers:** `Authorization: Bearer token`

**Request:**

```json
{
  "phone": "555-9876",
  "vehicle": "motorcycle",
  "license": "DL123456",
  "profileImage": "image_url"
}
```

#### 2. Get Rider Profile

```
GET /api/rider
```

**Headers:** `Authorization: Bearer token`

#### 3. Update Availability

```
PUT /api/rider/status
```

**Headers:** `Authorization: Bearer token`

**Request:**

```json
{
  "isOnline": true,
  "currentLocation": {
    "lat": 40.7128,
    "lng": -74.006
  }
}
```

---

### Order Delivery

#### 1. Accept Order

```
POST /api/rider/order/:orderId/accept
```

**Headers:** `Authorization: Bearer token`

#### 2. Update Delivery Status

```
PUT /api/rider/order/:orderId/status
```

**Request:**

```json
{
  "status": "picked_up", // "accepted" | "picked_up" | "delivered"
  "location": { "lat": 40.7128, "lng": -74.006 }
}
```

#### 3. Get Available Orders

```
GET /api/rider/available-orders
```

**Headers:** `Authorization: Bearer token`

**Query Params:**

- `latitude` - rider's current latitude
- `longitude` - rider's current longitude

---

## Utils Service

**Base URL:** `http://localhost:5002` | **Port:** `5002`

### Payment Processing

#### 1. Create Razorpay Order

```
POST /api/payment/create-order
```

**Headers:** `Authorization: Bearer token`

**Request:**

```json
{
  "amount": 1299,
  "currency": "INR",
  "orderId": "order_id"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "razorpayOrderId": "order_...",
  "amount": 1299,
  "currency": "INR"
}
```

#### 2. Verify Payment

```
POST /api/payment/verify
```

**Request:**

```json
{
  "razorpayOrderId": "order_...",
  "razorpayPaymentId": "pay_...",
  "razorpaySignature": "signature_...",
  "orderId": "order_id"
}
```

**Response:** `200 OK`

```json
{
  "success": true,
  "message": "Payment verified"
}
```

#### 3. Upload to Cloudinary

```
POST /api/cloudinary/upload
```

**Headers:** `Authorization: Bearer token`, `Content-Type: multipart/form-data`

**Request Form Data:**

- `file` - image file

---

## Admin Service

**Base URL:** `http://localhost:5003` | **Port:** `5003`

### Verification Management

#### 1. Get Pending Verifications

```
GET /api/admin/pending
```

**Headers:** `Authorization: Bearer token` (Admin only)

**Query Params:**

- `type` - "restaurant" | "rider"

#### 2. Approve Restaurant

```
POST /api/admin/restaurant/:restaurantId/approve
```

**Headers:** `Authorization: Bearer token` (Admin only)

#### 3. Reject Restaurant

```
POST /api/admin/restaurant/:restaurantId/reject
```

**Headers:** `Authorization: Bearer token` (Admin only)

**Request:**

```json
{
  "reason": "Incomplete documentation"
}
```

#### 4. Approve Rider

```
POST /api/admin/rider/:riderId/approve
```

#### 5. Get Statistics

```
GET /api/admin/statistics
```

**Headers:** `Authorization: Bearer token` (Admin only)

**Response:**

```json
{
  "totalUsers": 1500,
  "totalRestaurants": 250,
  "totalRiders": 350,
  "totalOrders": 5000,
  "revenue": 125000
}
```

---

## Realtime Service

**Base URL:** `ws://localhost:5004` | **Port:** `5004`

### WebSocket Events

#### Connection

```javascript
const socket = io("http://localhost:5004", {
  auth: { token: "jwt_token" },
});
```

#### Events

**Join Order**

```javascript
socket.emit("join-order", { orderId: "order_id" });
```

**Order Updated**

```javascript
socket.on("order-updated", (data) => {
  // { orderId, status, riderLocation, ... }
});
```

**Rider Location Updated**

```javascript
socket.on("rider-location", (data) => {
  // { riderId, lat, lng, timestamp }
});
```

**Order Notification**

```javascript
socket.on("order-notification", (data) => {
  // New order for restaurant/rider
});
```

---

## Error Responses

All services return error responses in this format:

```json
{
  "success": false,
  "message": "Error message",
  "statusCode": 400
}
```

### Common Status Codes

- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

---

## Authentication

All protected endpoints require JWT token in header:

```
Authorization: Bearer <jwt_token>
```

Token expires in **7 days** by default.

---

## Rate Limiting

- Default: 100 requests per 15 minutes
- Auth endpoints: 5 requests per 15 minutes (login/register)
- Payment endpoints: 20 requests per 15 minutes
