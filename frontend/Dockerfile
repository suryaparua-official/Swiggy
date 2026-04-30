# ─────────────────────────────────────────────
# Frontend Dockerfile (React + Vite + nginx)
# Multi-stage build → final image ~30MB
# ─────────────────────────────────────────────

# ===== Stage 1: Builder =====
FROM node:22-alpine AS builder

WORKDIR /app

RUN apk --no-cache upgrade

# Vite requires environment variables at build time
# Inject via build args (in production use: docker build --build-arg)
ARG VITE_AUTH_URL
ARG VITE_RESTAURANT_URL
ARG VITE_UTILS_URL
ARG VITE_REALTIME_URL
ARG VITE_RIDER_URL
ARG VITE_ADMIN_URL
ARG VITE_GOOGLE_CLIENT_ID
ARG VITE_STRIPE_PUBLISHABLE_KEY
ARG VITE_INTERNAL_SERVICE_KEY

ENV VITE_AUTH_URL=$VITE_AUTH_URL
ENV VITE_RESTAURANT_URL=$VITE_RESTAURANT_URL
ENV VITE_UTILS_URL=$VITE_UTILS_URL
ENV VITE_REALTIME_URL=$VITE_REALTIME_URL
ENV VITE_RIDER_URL=$VITE_RIDER_URL
ENV VITE_ADMIN_URL=$VITE_ADMIN_URL
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID
ENV VITE_STRIPE_PUBLISHABLE_KEY=$VITE_STRIPE_PUBLISHABLE_KEY
ENV VITE_INTERNAL_SERVICE_KEY=$VITE_INTERNAL_SERVICE_KEY

# Install dependencies (cache-friendly)
COPY package*.json ./
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build


# ===== Stage 2: nginx production =====
FROM nginx:1.27-alpine

RUN apk --no-cache upgrade

# Remove default nginx config and use custom config
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files from builder stage to nginx serve directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose nginx port 80
EXPOSE 80

# Run nginx in foreground (required for Docker)
CMD ["nginx", "-g", "daemon off;"]