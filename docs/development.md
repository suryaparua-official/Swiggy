# Development Guide

Complete guide for local development setup, testing, and contributing to Swiggy.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Development Workflow](#development-workflow)
- [Testing Strategy](#testing-strategy)
- [Code Style & Conventions](#code-style--conventions)
- [Debugging Tips](#debugging-tips)
- [Git Workflow](#git-workflow)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

- **Node.js:** v18.x or higher
- **Docker & Docker Compose:** Latest version
- **MongoDB:** Running locally or MongoDB Atlas account
- **RabbitMQ:** Running locally or CloudAMQP account
- **Git:** For version control
- **VS Code:** Recommended IDE

### Optional Tools

- **Postman:** API testing
- **MongoDB Compass:** Database GUI
- **RabbitMQ Management UI:** Queue monitoring

---

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/suryaparua-official/Swiggy.git
cd Swiggy
```

### 2. Install Dependencies

```bash
# Install root dependencies
npm install

# Install service dependencies
cd services/auth && npm install
cd ../restaurant && npm install
cd ../rider && npm install
cd ../utils && npm install
cd ../admin && npm install
cd ../realtime && npm install

# Install frontend dependencies
cd ../../frontend && npm install
```

### 3. Set Up Environment Variables

Create `.env` files in each service:

**services/auth/.env**

```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/swiggy
JWT_SECRET=your-secret-key-change-this
JWT_EXPIRY=7d
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
NODE_ENV=development
```

**services/restaurant/.env**

```
PORT=5001
MONGODB_URI=mongodb://localhost:27017/swiggy
JWT_SECRET=your-secret-key-change-this
RABBITMQ_URL=amqp://guest:guest@localhost:5672
ORDER_QUEUE=orders-queue
ORDER_READY_QUEUE=order-ready-queue
CLOUDINARY_NAME=your-cloudinary-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
NODE_ENV=development
```

**frontend/.env**

```
VITE_API_BASE_URL=http://localhost:5001
VITE_AUTH_API=http://localhost:5000
VITE_SOCKET_URL=http://localhost:5004
VITE_RAZORPAY_KEY=your-razorpay-key-id
```

### 4. Start Services with Docker Compose

```bash
# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f auth
docker-compose logs -f restaurant
```

### 5. Verify Setup

```bash
# Test Auth Service
curl http://localhost:5000/health

# Test Restaurant Service
curl http://localhost:5001/health

# Test Frontend
open http://localhost:5173
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
git branch -u origin/feature/your-feature-name
```

### 2. Make Changes

**For Backend Services:**

```bash
cd services/restaurant
npm run dev
```

**For Frontend:**

```bash
cd frontend
npm run dev
```

### 3. Test Changes

```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage

# Watch mode for TDD
npm run test:watch
```

### 4. Commit & Push

```bash
git add .
git commit -m "feat: add feature description"
git push origin feature/your-feature-name
```

### 5. Create Pull Request

- Push to GitHub and create PR
- Ensure CI/CD passes
- Request review from team members

---

## Testing Strategy

### Unit Tests

**Backend (Jest + ts-jest):**

```bash
npm test

# Run specific test file
npm test -- src/controllers/order.test.ts

# Watch mode
npm test -- --watch
```

**Frontend (Vitest):**

```bash
npm run test
npm run test:ui
npm run test:coverage
```

### Integration Tests

```bash
# Test with local MongoDB & RabbitMQ
npm run test:integration
```

### E2E Tests

```bash
# Frontend E2E with Playwright
cd frontend
npm run test:e2e
```

### Test Examples

**Backend Unit Test (Jest):**

```typescript
// src/controllers/order.test.ts
import { OrderController } from "./order";

describe("OrderController", () => {
  let controller: OrderController;

  beforeEach(() => {
    controller = new OrderController();
  });

  it("should create order successfully", async () => {
    const orderData = {
      restaurantId: "rest-123",
      items: [{ menuItemId: "item-1", quantity: 2 }],
      totalAmount: 500,
    };

    const result = await controller.createOrder(orderData);

    expect(result).toBeDefined();
    expect(result.orderId).toBeTruthy();
  });

  it("should throw error for invalid data", async () => {
    const invalidData = { restaurantId: "" };

    expect(() => controller.createOrder(invalidData)).rejects.toThrow(
      "Invalid order data",
    );
  });
});
```

**Frontend Component Test (Vitest):**

```typescript
// src/components/OrderCard.test.tsx
import { render, screen } from '@testing-library/react';
import { OrderCard } from './OrderCard';

describe('OrderCard', () => {
  it('should display order details', () => {
    const mockOrder = {
      id: 'ord-1',
      status: 'delivered',
      amount: 500,
      date: new Date()
    };

    render(<OrderCard order={mockOrder} />);

    expect(screen.getByText('Order #ord-1')).toBeInTheDocument();
    expect(screen.getByText('₹500')).toBeInTheDocument();
  });
});
```

---

## Code Style & Conventions

### TypeScript Configuration

All services use strict TypeScript settings (`tsconfig.json`):

```json
{
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### Naming Conventions

| Type             | Convention             | Example                                |
| ---------------- | ---------------------- | -------------------------------------- |
| Classes          | PascalCase             | `UserController`, `OrderService`       |
| Functions        | camelCase              | `getOrders()`, `createPayment()`       |
| Constants        | UPPER_SNAKE_CASE       | `MAX_RETRIES`, `API_TIMEOUT`           |
| Files            | kebab-case             | `order.controller.ts`, `user.model.ts` |
| React Components | PascalCase             | `OrderCard.tsx`, `UserProfile.tsx`     |
| React Hooks      | camelCase (use prefix) | `useOrders()`, `useAuth()`             |
| Routes           | kebab-case URLs        | `/api/restaurants`, `/api/orders`      |

### Code Style

**ESLint Configuration:**

```bash
# Run linter
npm run lint

# Fix linting errors
npm run lint:fix
```

**Prettier Configuration:**

```bash
# Format code
npm run format

# Check formatting
npm run format:check
```

### Folder Structure

**Backend Service:**

```
src/
├── config/       # Configuration files
├── controllers/  # Route handlers
├── models/       # Database models
├── routes/       # API routes
├── middleware/   # Express middleware
├── utils/        # Helper functions
├── types/        # TypeScript interfaces
└── index.ts      # Entry point
```

**Frontend:**

```
src/
├── components/   # React components
├── pages/        # Page components
├── context/      # Context API
├── utils/        # Helper functions
├── types.ts      # TypeScript interfaces
├── App.tsx       # Root component
└── main.tsx      # Entry point
```

---

## Debugging Tips

### Backend Debugging

**VS Code Debug Configuration (.vscode/launch.json):**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Restaurant Service",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "cwd": "${workspaceFolder}/services/restaurant",
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

**Using console.log effectively:**

```typescript
// Good - with context
console.log("Order created:", { orderId, customerId, total });

// Better - use custom logger
logger.info("Order created", { orderId, customerId, total });

// Avoid - unclear
console.log("result");
```

### Frontend Debugging

**React DevTools:**

- Install React DevTools browser extension
- Inspect component props and state
- Check context values in AppContext tab

**Network Debugging:**

```javascript
// Intercept API calls
const originalFetch = fetch;
window.fetch = function (...args) {
  console.log("API Call:", args[0]);
  return originalFetch.apply(this, args).then((response) => {
    console.log("Response:", response.status);
    return response;
  });
};
```

### Database Debugging

**MongoDB Queries:**

```bash
# Connect to MongoDB
mongosh "mongodb://localhost:27017/swiggy"

# View collections
show collections

# Query orders
db.orders.find({ customerId: ObjectId("...") })

# Check indexes
db.orders.getIndexes()
```

**RabbitMQ Debugging:**

- Access management UI: http://localhost:15672
- Check queue depths
- Monitor consumer connections
- View message payloads

---

## Git Workflow

### Branch Naming

```
feature/feature-name       # New feature
bugfix/bug-description     # Bug fix
hotfix/critical-issue      # Critical production fix
refactor/improvement-name  # Refactoring
docs/documentation-name    # Documentation
```

### Commit Message Format

Follow conventional commits:

```
<type>(<scope>): <subject>

<body>

<footer>

Examples:
- feat(order): add order tracking feature
- fix(auth): resolve JWT token validation issue
- docs(api): update API reference
- style(frontend): fix button styling
- refactor(restaurant): optimize menu loading
```

### Pull Request Process

1. Create feature branch
2. Make commits with meaningful messages
3. Keep PR focused (single feature/fix)
4. Add PR description explaining changes
5. Link related issues (#123)
6. Request review from team members
7. Resolve review comments
8. Merge when approved and CI passes

---

## Troubleshooting

### Common Issues

**1. MongoDB Connection Error**

```
Error: connect ECONNREFUSED 127.0.0.1:27017
```

**Solution:**

```bash
# Check if MongoDB is running
docker-compose ps | grep mongodb

# Restart MongoDB
docker-compose restart mongodb

# Verify connection
mongosh "mongodb://localhost:27017"
```

**2. RabbitMQ Connection Error**

```
Error: connect ECONNREFUSED 127.0.0.1:5672
```

**Solution:**

```bash
# Check if RabbitMQ is running
docker-compose ps | grep rabbitmq

# View RabbitMQ logs
docker-compose logs rabbitmq

# Restart RabbitMQ
docker-compose restart rabbitmq
```

**3. Port Already in Use**

```
Error: listen EADDRINUSE :::5001
```

**Solution:**

```bash
# Find process using port
lsof -i :5001

# Kill process
kill -9 <PID>

# Or use docker-compose to stop services
docker-compose down
```

**4. Frontend Not Connecting to Backend**

```
Error: Failed to fetch from http://localhost:5001
```

**Solution:**

- Check `.env` file has correct API URL
- Ensure backend service is running
- Check CORS headers in backend
- Use browser DevTools Network tab to inspect request

**5. Module Not Found Error**

```
Cannot find module '@/utils/helpers'
```

**Solution:**

```bash
# Clean and reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Clear TypeScript cache
npm run clean
npm run build
```

---

## Performance Tips

### Backend

- Use database indexes for frequently queried fields
- Implement caching for repeated queries
- Use pagination for large datasets
- Profile code with Node profiler

### Frontend

- Code splitting with React.lazy()
- Image optimization with WebP format
- Lazy load heavy components
- Use React Query for efficient data fetching

---

## Security Best Practices

1. **Never commit secrets** - Use `.env` files
2. **Validate all inputs** - Both frontend and backend
3. **Use HTTPS** - In production
4. **Rate limiting** - Protect APIs from abuse
5. **SQL/NoSQL injection** - Use parameterized queries
6. **XSS protection** - Sanitize user inputs in frontend
7. **CSRF tokens** - For state-changing operations
8. **Keep dependencies updated** - Regular npm audit

---

## Resources

- [Node.js Documentation](https://nodejs.org/docs/)
- [Express.js Guide](https://expressjs.com/)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [React Documentation](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Docker Documentation](https://docs.docker.com/)
