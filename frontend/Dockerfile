# ─────────────────────────────────────────────
# Frontend Dockerfile (React + Vite + nginx)
# Multi-stage build → final image ~30MB
# ─────────────────────────────────────────────

# ===== Stage 1: Builder =====
FROM node:22-alpine AS builder

WORKDIR /app

# Vite requires environment variables at build time
# Inject via build args (in production use: docker build --build-arg)
ARG VITE_API_URL
ARG VITE_GOOGLE_CLIENT_ID
ARG VITE_RAZORPAY_KEY
ARG VITE_STRIPE_PUBLIC_KEY

# Set build-time environment variables
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID
ENV VITE_RAZORPAY_KEY=$VITE_RAZORPAY_KEY
ENV VITE_STRIPE_PUBLIC_KEY=$VITE_STRIPE_PUBLIC_KEY

# Install dependencies (cache-friendly)
COPY package*.json ./
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build


# ===== Stage 2: nginx production =====
FROM nginx:1.27-alpine

# Remove default nginx config and use custom config
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files from builder stage to nginx serve directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose nginx port 80
EXPOSE 80

# Run nginx in foreground (required for Docker)
CMD ["nginx", "-g", "daemon off;"]