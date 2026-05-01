# Local Development Setup Guide

This guide walks through setting up the entire project locally using Docker Compose.

## Prerequisites

- Docker Desktop (with WSL 2 backend on Windows)
- Node.js v22+ (optional, only if running services without Docker)
- Git

## Quick Start

```bash
# 1. Clone
git clone https://github.com/suryaparua-official/Swiggy.git
cd Swiggy-main

# 2. Create env file
cp .env.example .env
# Edit .env with your credentials (see below)

# 3. Start everything
docker compose up --build

# 4. Open http://localhost:3000
```

## Getting Credentials

### Google OAuth (Required for login)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google+ API
4. Go to **APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID**
5. Application type: **Web application**
6. Add Authorized JavaScript origins:
   - `http://localhost:3000`
   - `http://localhost:5173`
7. Copy **Client ID** and **Client Secret**

### Cloudinary (Required for images)

1. Create free account at [cloudinary.com](https://cloudinary.com)
2. Dashboard → Copy **Cloud Name**, **API Key**, **API Secret**

### RabbitMQ (Required for order flow)

1. Create free account at [cloudamqp.com](https://cloudamqp.com)
2. Create new instance (Little Lemur — Free plan)
3. Click instance → Copy **AMQP URL**
   - Format: `amqps://user:pass@host/vhost`

### Razorpay (For Indian payment testing)

1. Create account at [razorpay.com](https://razorpay.com)
2. Settings → API Keys → Generate Test Key
3. Copy Key ID and Key Secret

### Stripe (For international payment testing)

1. Create account at [stripe.com](https://stripe.com)
2. Developers → API Keys
3. Copy Secret key and Publishable key

## Environment File

```env
# JWT
JWT_SEC=any_random_long_string_like_this_1234567890abcdef

# Google OAuth
GOOGLE_CLIENT_ID=491400024355-xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxx

# Internal service key (any random string)
INTERNAL_SERVICE_KEY=another_random_string_for_internal_auth

# Cloudinary
CLOUD_NAME=your_cloud_name
CLOUD_API_KEY=123456789012345
CLOUD_SECRET_KEY=your_secret_key

# Razorpay
RAZORPAY_KEY_ID=rzp_test_xxx
RAZORPAY_KEY_SECRET=your_secret

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx

# RabbitMQ
RABBITMQ_URL=amqps://user:pass@host/vhost

# Queue names (keep these as-is)
PAYMENT_QUEUE=payment_event
RIDER_QUEUE=rider_queue
ORDER_READY_QUEUE=order_ready_queue
```

## Useful Commands

```bash
# View logs for a specific service
docker compose logs -f auth
docker compose logs -f restaurant
docker compose logs -f frontend

# Restart a specific service
docker compose restart restaurant

# Stop all services
docker compose down

# Stop and remove all data (database will be wiped)
docker compose down -v

# Rebuild a specific service after code change
docker compose up --build auth
```

## Testing the Application

### Create an Admin User

After the app is running, connect to MongoDB and set a user as admin:

```bash
# If running locally with Docker Compose
docker compose exec mongodb mongosh

# In MongoDB shell:
use Zomato_Clone
db.users.updateOne(
  { email: "your-email@gmail.com" },
  { $set: { role: "admin" } }
)
```

### Test Payment Flow (Razorpay Test Mode)

Use these test card details:

- Card: `4111 1111 1111 1111`
- Expiry: Any future date
- CVV: Any 3 digits
- OTP: `1234` (test mode)

### Test Order Flow

1. Login as **customer**
2. Allow location access
3. Find a restaurant (must be verified and open)
4. Add items to cart
5. Add delivery address
6. Checkout → Pay
7. Login as **restaurant seller** in another browser
8. See the order arrive in real-time
9. Update order status
10. Login as **rider** (must be verified and near the restaurant)
11. Go online → Accept order → Update status

## Common Issues

**Port already in use:**

```bash
# Check what's using port 5000
sudo lsof -i :5000
# Kill it or change the port in docker-compose.yml
```

**MongoDB connection refused:**

```bash
# Ensure MongoDB container is healthy
docker compose ps
docker compose logs mongodb
```

**RabbitMQ connection failed:**

- Verify RABBITMQ_URL in .env is correct
- Check CloudAMQP dashboard → the instance must be running

**Google login not working:**

- Verify GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are correct
- Verify the OAuth callback URLs include http://localhost:3000
