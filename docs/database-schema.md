# Database Schema & Models

MongoDB collections schema and relationships for Swiggy.

---

## Table of Contents

- [Users Collection](#users-collection)
- [Restaurants Collection](#restaurants-collection)
- [Menu Items Collection](#menu-items-collection)
- [Orders Collection](#orders-collection)
- [Riders Collection](#riders-collection)
- [Cart Collection](#cart-collection)
- [Addresses Collection](#addresses-collection)
- [Payments Collection](#payments-collection)

---

## Users Collection

Stores all user types (customer, restaurant owner, rider, admin).

```javascript
{
  _id: ObjectId,
  email: String,           // unique
  password: String,        // hashed
  name: String,
  phone: String,
  role: String,            // "customer" | "restaurant" | "rider" | "admin"
  profileImage: String,    // URL
  isVerified: Boolean,     // email verified
  isActive: Boolean,
  googleId: String,        // optional, for OAuth
  createdAt: Date,
  updatedAt: Date,

  // Role-specific fields (based on role)
  restaurantId: ObjectId,  // if role === "restaurant"
  riderId: ObjectId,       // if role === "rider"

  // Metadata
  lastLogin: Date,
  deviceTokens: [String]   // for push notifications
}
```

**Indexes:**

```javascript
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ phone: 1 });
db.users.createIndex({ role: 1 });
db.users.createIndex({ createdAt: -1 });
```

---

## Restaurants Collection

```javascript
{
  _id: ObjectId,
  ownerId: ObjectId,       // ref: Users._id
  name: String,
  description: String,
  phone: String,
  email: String,

  // Location
  address: {
    street: String,
    city: String,
    state: String,
    zipcode: String,
    lat: Number,
    lng: Number
  },

  // Details
  cuisine: [String],       // ["Italian", "Pizza", "Pasta"]
  operatingHours: {
    monday: { open: String, close: String },
    tuesday: { open: String, close: String },
    // ... rest of days
  },

  // Media
  profileImage: String,
  bannerImage: String,

  // Stats
  rating: Number,          // 0-5
  totalOrders: Number,
  totalReviews: Number,

  // Status
  isVerified: Boolean,     // by admin
  isActive: Boolean,
  verificationStatus: String, // "pending" | "approved" | "rejected"
  rejectionReason: String,

  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**

```javascript
db.restaurants.createIndex({ ownerId: 1 });
db.restaurants.createIndex({ isVerified: 1, isActive: 1 });
db.restaurants.createIndex({ "address.lat": 1, "address.lng": 1 });
db.restaurants.createIndex({ createdAt: -1 });
db.restaurants.createIndex({ name: "text", description: "text" });
```

---

## Menu Items Collection

```javascript
{
  _id: ObjectId,
  restaurantId: ObjectId,  // ref: Restaurants._id
  name: String,
  description: String,
  price: Number,

  // Categorization
  category: String,        // "Pizza", "Pasta", "Appetizers", etc.
  subcategory: String,     // optional

  // Properties
  vegetarian: Boolean,
  vegan: Boolean,
  glutenFree: Boolean,
  spicy: Boolean,

  // Media
  image: String,           // URL

  // Availability
  isAvailable: Boolean,

  // Customization options
  addons: [{
    _id: ObjectId,
    name: String,
    price: Number,
    isRequired: Boolean,
    options: [String]       // e.g., ["Small", "Medium", "Large"]
  }],

  // Stats
  totalSold: Number,
  averageRating: Number,

  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**

```javascript
db.menu_items.createIndex({ restaurantId: 1 });
db.menu_items.createIndex({ restaurantId: 1, isAvailable: 1 });
db.menu_items.createIndex({ category: 1 });
```

---

## Orders Collection

```javascript
{
  _id: ObjectId,
  orderId: String,         // unique, human-readable: "ORD-2024-001"

  // Parties involved
  customerId: ObjectId,    // ref: Users._id
  restaurantId: ObjectId,  // ref: Restaurants._id
  riderId: ObjectId,       // ref: Riders._id (assigned during delivery)

  // Items
  items: [{
    _id: ObjectId,
    menuItemId: ObjectId,  // ref: MenuItems._id
    name: String,
    price: Number,
    quantity: Number,
    addons: [{
      name: String,
      price: Number
    }],
    subtotal: Number
  }],

  // Pricing
  subtotal: Number,
  taxAmount: Number,
  deliveryFee: Number,
  discountAmount: Number,
  totalAmount: Number,

  // Addresses
  deliveryAddress: {
    street: String,
    city: String,
    zipcode: String,
    lat: Number,
    lng: Number,
    instructions: String
  },

  // Status tracking
  orderStatus: String,     // "pending" | "confirmed" | "preparing" | "ready" | "picked_up" | "delivered" | "cancelled"
  paymentStatus: String,   // "pending" | "completed" | "failed"
  deliveryStatus: String,  // "not_assigned" | "assigned" | "picked_up" | "in_transit" | "delivered"

  // Payment
  paymentMethod: String,   // "card" | "upi" | "wallet" | "cash"
  razorpayOrderId: String,
  razorpayPaymentId: String,

  // Timeline
  createdAt: Date,
  confirmedAt: Date,
  readyAt: Date,
  pickedUpAt: Date,
  deliveredAt: Date,
  estimatedDeliveryTime: Date,

  // Notes
  specialInstructions: String,
  cancellationReason: String,

  // Tracking
  riderLocations: [{
    timestamp: Date,
    lat: Number,
    lng: Number
  }],

  // Ratings (after delivery)
  customerRating: Number,   // 1-5
  customerReview: String,
  restaurantRating: Number,
  riderRating: Number
}
```

**Indexes:**

```javascript
db.orders.createIndex({ orderId: 1 }, { unique: true });
db.orders.createIndex({ customerId: 1, createdAt: -1 });
db.orders.createIndex({ restaurantId: 1, createdAt: -1 });
db.orders.createIndex({ riderId: 1, orderStatus: 1 });
db.orders.createIndex({ orderStatus: 1 });
db.orders.createIndex({ createdAt: -1 });
db.orders.createIndex({ "deliveryAddress.lat": 1, "deliveryAddress.lng": 1 });
```

---

## Riders Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId,        // ref: Users._id

  // Personal Info
  phone: String,
  dateOfBirth: Date,

  // Vehicle & License
  vehicle: String,         // "motorcycle" | "bicycle" | "car"
  vehicleNumber: String,
  license: String,         // driver's license number
  licenseExpiry: Date,

  // Verification
  isVerified: Boolean,     // by admin
  verificationStatus: String, // "pending" | "approved" | "rejected"
  rejectionReason: String,

  // Profile
  profileImage: String,
  documentImage: String,

  // Availability
  isOnline: Boolean,
  currentLocation: {
    lat: Number,
    lng: Number,
    updatedAt: Date
  },
  serviceRadius: Number,   // in km

  // Stats
  totalOrders: Number,
  totalEarnings: Number,
  averageRating: Number,
  totalReviews: Number,
  acceptanceRate: Number,  // percentage
  cancellationRate: Number,

  // Status
  status: String,          // "active" | "inactive" | "suspended"
  bankDetails: {
    accountHolder: String,
    accountNumber: String,
    ifscCode: String,
    bankName: String
  },

  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**

```javascript
db.riders.createIndex({ userId: 1 });
db.riders.createIndex({ isVerified: 1, isOnline: 1 });
db.riders.createIndex({ "currentLocation.lat": 1, "currentLocation.lng": 1 });
db.riders.createIndex({ createdAt: -1 });
```

---

## Cart Collection

```javascript
{
  _id: ObjectId,
  customerId: ObjectId,    // ref: Users._id
  restaurantId: ObjectId,  // ref: Restaurants._id

  items: [{
    _id: ObjectId,
    menuItemId: ObjectId,  // ref: MenuItems._id
    name: String,
    price: Number,
    quantity: Number,
    addons: [{
      name: String,
      price: Number
    }],
    subtotal: Number
  }],

  subtotal: Number,
  taxAmount: Number,
  deliveryFee: Number,
  totalAmount: Number,

  couponCode: String,      // optional
  discountAmount: Number,

  createdAt: Date,
  updatedAt: Date,
  expiresAt: Date          // 24 hours from creation
}
```

**Indexes:**

```javascript
db.carts.createIndex({ customerId: 1, restaurantId: 1 }, { unique: true });
db.carts.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index
```

---

## Addresses Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId,        // ref: Users._id

  label: String,           // "Home" | "Work" | "Other"
  street: String,
  city: String,
  state: String,
  zipcode: String,

  location: {
    type: "Point",
    coordinates: [Number, Number] // [lng, lat]
  },

  phone: String,
  instructions: String,

  isDefault: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**

```javascript
db.addresses.createIndex({ userId: 1 });
db.addresses.createIndex({ location: "2dsphere" });
db.addresses.createIndex({ userId: 1, isDefault: 1 });
```

---

## Payments Collection

```javascript
{
  _id: ObjectId,
  orderId: ObjectId,       // ref: Orders._id
  userId: ObjectId,        // ref: Users._id

  amount: Number,
  currency: String,        // "INR"
  paymentMethod: String,   // "card" | "upi" | "wallet" | "cash"

  // Razorpay Integration
  razorpayOrderId: String,
  razorpayPaymentId: String,
  razorpaySignature: String,

  // Status
  status: String,          // "pending" | "completed" | "failed" | "refunded"

  // Refund
  refundAmount: Number,
  refundId: String,
  refundReason: String,

  // Metadata
  createdAt: Date,
  completedAt: Date,
  failureMessage: String
}
```

**Indexes:**

```javascript
db.payments.createIndex({ orderId: 1 });
db.payments.createIndex({ userId: 1, createdAt: -1 });
db.payments.createIndex({ razorpayOrderId: 1 });
db.payments.createIndex({ status: 1 });
```

---

## Relationships

```
Users
  ├── owns → Restaurants
  ├── places → Orders
  ├── manages → Addresses
  └── makes → Payments

Restaurants
  ├── has → MenuItems
  ├── receives → Orders
  └── employs → (implicit via Order.riderId)

MenuItems
  ├── belongs to → Restaurants
  └── appears in → Orders

Orders
  ├── placed by → Users (customerId)
  ├── from → Restaurants
  ├── assigned to → Riders (riderId)
  ├── has → Payments
  └── uses → Addresses

Riders
  ├── completes → Orders
  └── owns location → (currentLocation)

Carts
  ├── belongs to → Users
  └── contains → MenuItems (from Restaurants)

Addresses
  ├── owned by → Users
  └── used in → Orders

Payments
  ├── associated with → Orders
  └── made by → Users
```

---

## Data Consistency Rules

1. **Referential Integrity:**
   - Delete user → cascade delete all orders, carts, addresses
   - Delete restaurant → cascade delete all menu items, mark orders as archived
   - Delete rider → reassign pending deliveries

2. **Cart Expiry:**
   - Carts expire after 24 hours of inactivity
   - TTL index handles automatic cleanup

3. **Order Status Flow:**
   - pending → confirmed → preparing → ready → picked_up → delivered
   - Can be cancelled at any point before picked_up

4. **Location Data:**
   - Uses GeoJSON for geospatial queries
   - Coordinates in [longitude, latitude] format

---

## Query Examples

**Find nearby restaurants:**

```javascript
db.restaurants.find({
  address: {
    $near: {
      $geometry: { type: "Point", coordinates: [lng, lat] },
      $maxDistance: 5000, // 5km in meters
    },
  },
});
```

**Get active orders for a restaurant:**

```javascript
db.orders.find({
  restaurantId: ObjectId,
  orderStatus: { $in: ["pending", "confirmed", "preparing", "ready"] },
});
```

**Calculate daily revenue:**

```javascript
db.orders.aggregate([
  {
    $match: {
      createdAt: {
        $gte: ISODate("2024-01-01"),
        $lt: ISODate("2024-01-02"),
      },
      paymentStatus: "completed",
    },
  },
  {
    $group: {
      _id: "$restaurantId",
      totalRevenue: { $sum: "$totalAmount" },
      totalOrders: { $sum: 1 },
    },
  },
]);
```
