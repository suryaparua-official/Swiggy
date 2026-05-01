# Frontend Architecture & Guide

Complete guide to Swiggy frontend built with React, TypeScript, and Vite.

---

## Table of Contents

- [Project Structure](#project-structure)
- [Core Technologies](#core-technologies)
- [State Management](#state-management)
- [Component Architecture](#component-architecture)
- [Routing](#routing)
- [Real-time Features](#real-time-features)
- [API Integration](#api-integration)
- [Performance Optimization](#performance-optimization)
- [Deployment](#deployment)

---

## Project Structure

```
frontend/
├── public/                  # Static assets
│   ├── favicon.ico
│   └── manifest.json
├── src/
│   ├── assets/             # Images, fonts, styles
│   ├── components/         # Reusable components
│   │   ├── navbar.tsx
│   │   ├── OrderCard.tsx
│   │   ├── RestaurantCard.tsx
│   │   ├── protectedRoute.tsx
│   │   ├── publicRoute.tsx
│   │   └── ...
│   ├── context/            # Context API state
│   │   ├── AppContext.tsx  # Global app state
│   │   └── SocketContext.tsx # WebSocket state
│   ├── pages/              # Page components
│   │   ├── Home.tsx
│   │   ├── Login.tsx
│   │   ├── Cart.tsx
│   │   ├── Orders.tsx
│   │   ├── Restaurant.tsx
│   │   ├── RiderDashboard.tsx
│   │   └── ...
│   ├── utils/              # Utility functions
│   │   └── orderflow.ts
│   ├── types.ts            # TypeScript types
│   ├── App.tsx             # Root component
│   ├── main.tsx            # Entry point
│   └── index.css           # Global styles
├── .env                    # Environment variables
├── .gitignore
├── eslint.config.js        # ESLint configuration
├── index.html              # HTML template
├── nginx.conf              # Nginx configuration
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── vite.config.ts          # Vite configuration
└── vercel.json             # Vercel deployment config
```

---

## Core Technologies

### Dependencies

- **React 18.x** - UI library
- **TypeScript** - Type safety
- **Vite** - Fast build tool
- **React Router** - Client-side routing
- **Socket.io** - Real-time communication
- **Axios** - HTTP client
- **TailwindCSS** - Styling
- **Zustand** - State management (optional)

### Dev Dependencies

- **Vitest** - Unit testing
- **@testing-library/react** - Component testing
- **Playwright** - E2E testing
- **ESLint** - Code linting
- **Prettier** - Code formatting

---

## State Management

### AppContext (Global State)

**File:** `src/context/AppContext.tsx`

```typescript
interface User {
  id: string;
  email: string;
  name: string;
  role: "customer" | "restaurant" | "rider" | "admin";
  profileImage?: string;
}

interface Restaurant {
  _id: string;
  name: string;
  address: Address;
  cuisine: string[];
  rating: number;
  distance?: number;
}

interface AppContextType {
  // User state
  user: User | null;
  isAuthenticated: boolean;
  setUser: (user: User | null) => void;
  logout: () => void;

  // Cart state
  cart: CartItem[];
  selectedRestaurant: Restaurant | null;
  addToCart: (item: CartItem) => void;
  removeFromCart: (itemId: string) => void;
  clearCart: () => void;

  // UI state
  loading: boolean;
  error: string | null;
  setError: (error: string | null) => void;
}

export const AppContext = createContext<AppContextType | undefined>(undefined);

// Usage in components
const { user, cart, addToCart } = useContext(AppContext)!;
```

### SocketContext (WebSocket State)

**File:** `src/context/SocketContext.tsx`

```typescript
interface SocketContextType {
  socket: Socket | null;
  connected: boolean;

  // Order tracking
  currentOrder: Order | null;
  riderLocation: Location | null;
  estimatedTime: number | null;

  // Events
  joinOrder: (orderId: string) => void;
  leaveOrder: () => void;

  // Notifications
  notification: Notification | null;
  clearNotification: () => void;
}

export const SocketContext = createContext<SocketContextType | undefined>(
  undefined,
);
```

---

## Component Architecture

### Component Hierarchy

```
App
├── Layout
│   ├── Navbar
│   ├── Sidebar (optional)
│   └── MainContent
│       └── Router
│           ├── PublicRoute
│           │   ├── Home
│           │   ├── Login
│           │   └── Restaurant
│           └── ProtectedRoute
│               ├── Cart
│               ├── Checkout
│               ├── Orders
│               ├── RiderDashboard
│               └── AdminDashboard
└── Modals/Notifications
```

### Component Types

**Page Components** (in `pages/`):

- Full-page components corresponding to routes
- Handle page-level logic and data fetching

**Container Components** (in `components/`):

- Connect to context/state
- Handle business logic
- Pass props to presentational components

**Presentational Components** (in `components/`):

- Receive props and render UI
- Minimal logic
- Highly reusable

### Example Component

```typescript
// src/components/RestaurantCard.tsx
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Restaurant } from '../types';

interface RestaurantCardProps {
  restaurant: Restaurant;
  onSelect?: (restaurant: Restaurant) => void;
}

export const RestaurantCard: React.FC<RestaurantCardProps> = ({
  restaurant,
  onSelect
}) => {
  const navigate = useNavigate();

  const handleClick = () => {
    onSelect?.(restaurant);
    navigate(`/restaurant/${restaurant._id}`);
  };

  return (
    <div
      className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow cursor-pointer"
      onClick={handleClick}
    >
      <img
        src={restaurant.profileImage}
        alt={restaurant.name}
        className="w-full h-48 object-cover rounded-t-lg"
      />
      <div className="p-4">
        <h3 className="text-lg font-bold">{restaurant.name}</h3>
        <p className="text-gray-600 text-sm">{restaurant.cuisine.join(', ')}</p>
        <div className="flex justify-between items-center mt-2">
          <span className="text-yellow-500">⭐ {restaurant.rating}</span>
          {restaurant.distance && (
            <span className="text-gray-500 text-sm">{restaurant.distance.toFixed(1)} km</span>
          )}
        </div>
      </div>
    </div>
  );
};
```

---

## Routing

### Route Configuration

**File:** `src/App.tsx`

```typescript
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ProtectedRoute, PublicRoute } from './components';
import { useContext } from 'react';
import { AppContext } from './context/AppContext';

export const App: React.FC = () => {
  const { isAuthenticated, user } = useContext(AppContext)!;

  return (
    <Router>
      <Routes>
        {/* Public Routes */}
        <Route element={<PublicRoute isAuthenticated={isAuthenticated} />}>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/restaurant/:id" element={<RestaurantPage />} />
        </Route>

        {/* Protected Routes - Customer */}
        <Route
          element={
            <ProtectedRoute
              isAuthenticated={isAuthenticated}
              requiredRole="customer"
              userRole={user?.role}
            />
          }
        >
          <Route path="/cart" element={<Cart />} />
          <Route path="/checkout" element={<Checkout />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/account" element={<Account />} />
        </Route>

        {/* Protected Routes - Restaurant Owner */}
        <Route
          element={
            <ProtectedRoute
              isAuthenticated={isAuthenticated}
              requiredRole="restaurant"
              userRole={user?.role}
            />
          }
        >
          <Route path="/restaurant/dashboard" element={<RestaurantDashboard />} />
          <Route path="/restaurant/menu" element={<MenuItems />} />
          <Route path="/restaurant/orders" element={<RestaurantOrders />} />
        </Route>

        {/* Protected Routes - Rider */}
        <Route
          element={
            <ProtectedRoute
              isAuthenticated={isAuthenticated}
              requiredRole="rider"
              userRole={user?.role}
            />
          }
        >
          <Route path="/rider/dashboard" element={<RiderDashboard />} />
          <Route path="/rider/orders" element={<RiderOrders />} />
        </Route>

        {/* Protected Routes - Admin */}
        <Route
          element={
            <ProtectedRoute
              isAuthenticated={isAuthenticated}
              requiredRole="admin"
              userRole={user?.role}
            />
          }
        >
          <Route path="/admin" element={<Admin />} />
          <Route path="/admin/restaurants" element={<AdminRestaurants />} />
          <Route path="/admin/riders" element={<AdminRiders />} />
        </Route>
      </Routes>
    </Router>
  );
};
```

---

## Real-time Features

### WebSocket Connection

**File:** `src/context/SocketContext.tsx`

```typescript
import { useEffect, useState, useCallback } from "react";
import { io, Socket } from "socket.io-client";

export const useSocket = () => {
  const [socket, setSocket] = useState<Socket | null>(null);

  useEffect(() => {
    const token = localStorage.getItem("token");
    const newSocket = io(import.meta.env.VITE_SOCKET_URL, {
      auth: { token },
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      reconnectionAttempts: 5,
    });

    // Connection events
    newSocket.on("connect", () => {
      console.log("Connected to realtime service");
    });

    newSocket.on("disconnect", () => {
      console.log("Disconnected from realtime service");
    });

    newSocket.on("error", (error) => {
      console.error("Socket error:", error);
    });

    setSocket(newSocket);

    return () => {
      newSocket.close();
    };
  }, []);

  return socket;
};

// Order tracking
export const useOrderTracking = (orderId: string) => {
  const socket = useSocket();
  const [order, setOrder] = useState<Order | null>(null);
  const [riderLocation, setRiderLocation] = useState<Location | null>(null);

  useEffect(() => {
    if (!socket) return;

    socket.emit("join-order", { orderId });

    socket.on("order-updated", (data) => {
      setOrder(data);
    });

    socket.on("rider-location", (data) => {
      setRiderLocation(data.location);
    });

    return () => {
      socket.emit("leave-order", { orderId });
      socket.off("order-updated");
      socket.off("rider-location");
    };
  }, [socket, orderId]);

  return { order, riderLocation };
};
```

---

## API Integration

### HTTP Client Setup

**File:** `src/utils/api.ts`

```typescript
import axios, { AxiosInstance, AxiosError } from "axios";

export const createApiClient = (baseURL: string): AxiosInstance => {
  const client = axios.create({
    baseURL,
    timeout: 10000,
    headers: {
      "Content-Type": "application/json",
    },
  });

  // Request interceptor
  client.interceptors.request.use((config) => {
    const token = localStorage.getItem("token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  // Response interceptor
  client.interceptors.response.use(
    (response) => response.data,
    (error: AxiosError) => {
      if (error.response?.status === 401) {
        // Redirect to login
        localStorage.removeItem("token");
        window.location.href = "/login";
      }
      return Promise.reject(error);
    },
  );

  return client;
};

export const authApi = createApiClient(import.meta.env.VITE_AUTH_API);
export const restaurantApi = createApiClient(import.meta.env.VITE_API_BASE_URL);
```

### API Hooks

**File:** `src/utils/hooks.ts`

```typescript
import { useState, useEffect } from "react";
import { restaurantApi } from "./api";

export const useRestaurants = (latitude?: number, longitude?: number) => {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchRestaurants = async () => {
      setLoading(true);
      try {
        const data = await restaurantApi.get("/api/restaurant", {
          params: { latitude, longitude },
        });
        setRestaurants(data.restaurants);
      } catch (err) {
        setError((err as Error).message);
      } finally {
        setLoading(false);
      }
    };

    fetchRestaurants();
  }, [latitude, longitude]);

  return { restaurants, loading, error };
};

export const useOrders = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const data = await restaurantApi.get("/api/orders");
      setOrders(data.orders);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  return { orders, loading, refetch: fetchOrders };
};
```

---

## Performance Optimization

### Code Splitting

```typescript
import { lazy, Suspense } from 'react';

const Cart = lazy(() => import('./pages/Cart'));
const Checkout = lazy(() => import('./pages/Checkout'));

<Suspense fallback={<LoadingSpinner />}>
  <Cart />
</Suspense>
```

### Image Optimization

```typescript
// Use WebP with fallback
<picture>
  <source srcSet="image.webp" type="image/webp" />
  <img src="image.jpg" alt="description" loading="lazy" />
</picture>
```

### Memoization

```typescript
import { memo, useMemo, useCallback } from 'react';

export const OrderList = memo(({ orders }: Props) => {
  const sortedOrders = useMemo(
    () => orders.sort((a, b) => b.createdAt - a.createdAt),
    [orders]
  );

  const handleDelete = useCallback((id: string) => {
    // deletion logic
  }, []);

  return <ul>{/* render list */}</ul>;
});
```

---

## Deployment

### Build

```bash
npm run build
```

Outputs optimized build to `dist/` directory.

### Environment Configuration

**.env files:**

```
VITE_API_BASE_URL=http://localhost:5001
VITE_AUTH_API=http://localhost:5000
VITE_SOCKET_URL=http://localhost:5004
VITE_RAZORPAY_KEY=key_id
```

### Docker Deployment

**Dockerfile:**

```dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Production Optimization

- Minification & code splitting enabled by Vite
- Gzip compression via nginx
- Cache busting with hashed filenames
- SEO optimization ready

---

## Best Practices

1. **Component Reusability** - Keep components small and focused
2. **Type Safety** - Use TypeScript strictly
3. **State Lifting** - Avoid prop drilling, use context
4. **Error Boundaries** - Gracefully handle errors
5. **Accessibility** - Use semantic HTML, ARIA labels
6. **Performance** - Lazy load, memoize, optimize images
7. **Testing** - Test critical user flows
8. **Documentation** - Comment complex logic
