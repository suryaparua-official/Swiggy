# Swiggy — Food Delivery Platform

A production-grade, cloud-native food delivery application built with a microservices architecture and deployed on Google Kubernetes Engine (GKE) using a full DevSecOps pipeline.

> **Live Demo:** https://swiggy-surya.duckdns.org

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Services](#-services)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Local Development Setup](#-local-development-setup)
- [Cloud Deployment (GCP + GKE)](#-cloud-deployment-gcp--gke)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Monitoring & Observability](#-monitoring--observability)
- [Alerting](#-alerting)
- [Security](#-security)
- [API Reference](#-api-reference)
- [Environment Variables](#-environment-variables)
- [Contributing](#-contributing)

---

## 📄 Project Report

A complete technical report covering architecture, system design, infrastructure, CI/CD, monitoring, cost analysis, and deployment guide is available:

[![View Full Report](https://img.shields.io/badge/📄_Full_Technical_Report-View_PDF-red?style=for-the-badge)](https://drive.google.com/file/d/1oOQgKfPxiEWupUYhOeUXy6AY56kVEEX_/view?usp=sharing)

> Covers: Architecture · Microservices Design · GCP Infrastructure · CI/CD Pipeline · Security · Monitoring · Cost Analysis · API Reference · SLOs

---

## 🌟 Overview

Tomato is a full-stack food delivery platform similar to Swiggy/Zomato. It supports three types of users:

| Role                          | Capabilities                                                                                  |
| ----------------------------- | --------------------------------------------------------------------------------------------- |
| **Customer**                  | Browse nearby restaurants, add to cart, place orders, pay online, track delivery in real-time |
| **Restaurant Owner (Seller)** | Manage restaurant profile, menu items, receive and process orders                             |
| **Delivery Rider**            | Register profile, go online/offline, receive order notifications, update delivery status      |
| **Admin**                     | Verify restaurants and riders before they go live                                             |

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                 │
└─────────────────────────────┬───────────────────────────────────┘
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              GCP Global Load Balancer (GKE Ingress)             │
│                    swiggy-surya.duckdns.org                     │
│                  SSL: GKE Managed Certificate                   │
└──────┬───────┬───────┬───────┬───────┬───────┬───────┬──────────┘
       │       │       │       │       │       │       │
       ▼       ▼       ▼       ▼       ▼       ▼       ▼
  Frontend  Auth    Restaurant  Utils  Realtime  Rider  Admin
   :80     :5000    :5001     :5002   :5004    :5005  :5006
                       │               │
                       ▼               ▼
              ┌─────────────┐  ┌──────────────┐
              │ MongoDB     │  │  Socket.io   │
              │ Atlas       │  │  WebSocket   │
              └─────────────┘  └──────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   CloudAMQP     │
              │   (RabbitMQ)    │
              └─────────────────┘
```

### Microservices Communication

```
                    ┌─────────────┐
                    │   Frontend  │
                    │  (React)    │
                    └──────┬──────┘
                           │ REST API / WebSocket
          ┌────────────────┼────────────────────────┐
          │                │                        │
          ▼                ▼                        ▼
    ┌──────────┐    ┌──────────────┐         ┌──────────┐
    │   Auth   │    │  Restaurant  │         │  Utils   │
    │  :5000   │    │    :5001     │         │  :5002   │
    └──────────┘    └──────┬───────┘         └────┬─────┘
                           │                      │
                    ┌──────┴──────┐               │
                    │  RabbitMQ   │               │
                    │  Queues     │               │
                    └──────┬──────┘               │
                           │                      │
               ┌───────────┼───────────┐          │
               ▼           ▼           ▼          │
         ┌──────────┐ ┌─────────┐ ┌──────────┐    │
         │  Rider   │ │Realtime │ │  Admin   │    │
         │  :5005   │ │  :5004  │ │  :5006   │    │
         └──────────┘ └─────────┘ └──────────┘    │
                           ▲                      │
                           └──────────────────────┘
                              (payment events)
```

### Order Flow

```
Customer → Create Order → Payment (Razorpay/Stripe)
                              │
                              ▼ (PAYMENT_SUCCESS via RabbitMQ)
                         Restaurant ←── Updates order status
                              │
                              ▼ (ORDER_READY_FOR_RIDER via RabbitMQ)
                           Rider ←── Notified via Socket.io
                              │
                              ▼
                         Rider picks up → Delivers
                              │
                    Real-time updates via Socket.io
                    to Customer & Restaurant
```

### Infrastructure Architecture (GCP)

```
┌─────────────────────────────────────────────────────┐
│                  GCP Project                        │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │              VPC Network                     │   │
│  │                                              │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │         Subnet (10.0.0.0/18)           │  │   │
│  │  │                                        │  │   │
│  │  │  ┌─────────────────────────────────┐   │  │   │
│  │  │  │    GKE Cluster (asia-south1-a)  │   │  │   │
│  │  │  │                                 │   │  │   │
│  │  │  │  Node Pool: e2-medium × 2       │   │  │   │
│  │  │  │  Autoscaling: 1-4 nodes         │   │  │   │
│  │  │  │                                 │   │  │   │
│  │  │  │  Namespaces:                    │   │  │   │
│  │  │  │  ├── swiggy (app)               │   │  │   │
│  │  │  │  ├── argocd (gitops)            │   │  │   │
│  │  │  │  ├── monitoring (observability) │   │  │   │
│  │  │  │  └── tracing (jaeger)           │   │  │   │
│  │  │  └─────────────────────────────────┘   │  │   │
│  │  │                                        │  │   │
│  │  │  Cloud NAT ──► Internet                │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────┘   │
│                                                     │
│  GCS Bucket (Terraform State)                       │
│  Static IP (swiggy-ip)                              │
│  Managed SSL Certificate                            │
│  Workload Identity (GitHub Actions)                 │
└─────────────────────────────────────────────────────┘
```

### GitOps / CI-CD Pipeline

```
Developer pushes code
        │
        ▼
   GitHub Actions
   ┌─────────────────────────────────────────┐
   │  CI Pipeline                            │
   │  ├── Snyk dependency scan               │
   │  ├── Docker build (7 services parallel) │
   │  ├── Trivy image vulnerability scan     │
   │  └── Push to DockerHub                  │
   └─────────────────┬───────────────────────┘
                     │ (on CI success)
                     ▼
   ┌─────────────────────────────────────────┐
   │  CD Pipeline                            │
   │  ├── Update image tags in k8s/          │
   │  ├── Git commit + push                  │
   │  ├── Auth to GCP (Workload Identity)    │
   │  └── Create/update K8s secrets          │
   └─────────────────┬───────────────────────┘
                     │
                     ▼
              ArgoCD watches GitHub
              Detects k8s/ changes
              Rolling deploy to GKE
                     │
                     ▼
              Zero-downtime update ✅
```

---

## 🛠️ Tech Stack

### Backend

| Technology           | Purpose                           |
| -------------------- | --------------------------------- |
| Node.js + TypeScript | Runtime & Language                |
| Express.js           | Web framework                     |
| MongoDB + Mongoose   | Database                          |
| RabbitMQ (CloudAMQP) | Message queue for async events    |
| Socket.io            | Real-time WebSocket communication |
| JWT                  | Authentication                    |
| Google OAuth 2.0     | Social login                      |
| Cloudinary           | Image storage                     |
| Razorpay             | Indian payment gateway            |
| Stripe               | International payment gateway     |

### Frontend

| Technology              | Purpose                 |
| ----------------------- | ----------------------- |
| React 19 + TypeScript   | UI framework            |
| Vite                    | Build tool              |
| Tailwind CSS            | Styling                 |
| React Router DOM        | Client-side routing     |
| Axios                   | HTTP client             |
| Socket.io Client        | Real-time updates       |
| Leaflet + React-Leaflet | Maps for order tracking |

### Infrastructure & DevOps

| Technology       | Purpose                      |
| ---------------- | ---------------------------- |
| Docker           | Containerization             |
| Kubernetes (GKE) | Container orchestration      |
| Terraform        | Infrastructure as Code       |
| Ansible          | Configuration management     |
| ArgoCD           | GitOps continuous deployment |
| GitHub Actions   | CI/CD pipeline               |
| Helm             | Kubernetes package manager   |

### Observability

| Technology      | Purpose                            |
| --------------- | ---------------------------------- |
| Prometheus      | Metrics collection                 |
| Grafana         | Metrics visualization & dashboards |
| Loki + Promtail | Log aggregation                    |
| Alertmanager    | Alert routing (Slack/Email)        |
| Jaeger          | Distributed tracing                |

---

## 📦 Services

### 1. Auth Service (`/api/auth`) — Port 5000

Handles user authentication via Google OAuth 2.0.

**Endpoints:**
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/login` | Google OAuth login |
| PUT | `/api/auth/add/role` | Set user role (customer/rider/seller) |
| GET | `/api/auth/me` | Get current user profile |

### 2. Restaurant Service (`/api/restaurant`, `/api/item`, `/api/cart`, `/api/address`, `/api/order`) — Port 5001

The core service. Handles restaurants, menu items, shopping cart, delivery addresses, and order management.

**Key features:**

- Geospatial restaurant search (`$geoNear` MongoDB query)
- Order lifecycle management (placed → delivered)
- RabbitMQ consumer for payment success events
- RabbitMQ publisher for order-ready events

### 3. Utils Service (`/api/utils`, `/api/payment`, `/api/upload`) — Port 5002

Handles image uploads and payment processing.

**Endpoints:**
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/upload` | Upload image to Cloudinary |
| POST | `/api/payment/create/razorpay` | Create Razorpay order |
| POST | `/api/payment/verify/razorpay` | Verify Razorpay payment |
| POST | `/api/payment/create/stripe` | Create Stripe session |
| GET | `/api/payment/verify/stripe` | Verify Stripe payment |

### 4. Realtime Service (`/socket.io`) — Port 5004

Manages WebSocket connections. Other services call its internal HTTP endpoint to broadcast events.

**Events:**
| Event | Direction | Description |
|-------|-----------|-------------|
| `order:new` | → Restaurant | New paid order arrived |
| `order:update` | → Customer | Order status changed |
| `order:available` | → Rider | New order available |
| `order:rider_assigned` | → All | Rider accepted order |

### 5. Rider Service (`/api/rider`) — Port 5005

Manages delivery riders, availability, and order acceptance.

### 6. Admin Service (`/api/admin`, `/api/v1`) — Port 5006

Platform administration — verify restaurants and riders.

---

## 📁 Project Structure

```
Swiggy-main/
├── .github/
│   └── workflows/
│       ├── ci.yml              # Build, scan, push to DockerHub
│       └── cd.yml              # Deploy to GKE via ArgoCD
│
├── ansible/
│   ├── inventory.ini           # Target: localhost (kubectl)
│   ├── argocd.yml              # Install ArgoCD
│   ├── monitoring.yml          # Install Prometheus + Grafana + Loki
│   └── tracing.yml             # Install Jaeger + OpenTelemetry
│
├── docs/
│   ├── architecture.md         # Detailed architecture docs
│   ├── local-setup.md          # Local development guide
│   ├── slo.md                  # Service Level Objectives
│   ├── alerting-rules.md       # Alert rules documentation
│   └── runbooks/
│       ├── pod-crashloop.md    # How to fix CrashLoopBackOff
│       ├── high-memory.md      # High memory usage runbook
│       └── high-error-rate.md  # High error rate runbook
│
├── frontend/                   # React + Vite application
│   ├── src/
│   │   ├── pages/              # Route pages
│   │   ├── components/         # Reusable components
│   │   ├── context/            # React Context (AppContext, SocketContext)
│   │   └── types.ts            # TypeScript types
│   ├── Dockerfile              # Multi-stage: build + nginx
│   └── nginx.conf              # SPA routing config
│
├── k8s/                        # Kubernetes manifests (ArgoCD watches this)
│   ├── namespace.yml
│   ├── configmap.yml
│   ├── ingress.yml             # GCE Ingress with managed SSL
│   ├── managed-certificate.yml # GKE Managed Certificate
│   ├── argocd-app.yml          # ArgoCD Application definition
│   └── {service}/
│       ├── deployment.yml
│       └── service.yml
│
├── services/
│   ├── auth/                   # Google OAuth + JWT
│   ├── restaurant/             # Restaurants, menu, cart, orders
│   ├── utils/                  # Payments + image upload
│   ├── realtime/               # Socket.io WebSocket server
│   ├── rider/                  # Rider management
│   └── admin/                  # Platform administration
│
├── terraform/
│   ├── main.tf                 # Provider + GCS backend
│   ├── variables.tf            # Input variables
│   ├── vpc.tf                  # VPC, subnet, NAT, firewall
│   ├── gke.tf                  # GKE cluster + node pool
│   ├── iam.tf                  # Service accounts + Workload Identity
│   └── outputs.tf              # Output values for GitHub Secrets
│
├── docker-compose.yml          # Local development (all services)
└── .env.example                # Environment variables template
```

---

## ✅ Prerequisites

### Local Development

- [Node.js v22+](https://nodejs.org)
- [Docker Desktop](https://docker.com) (with WSL 2 on Windows)
- Git

### Cloud Deployment (Windows)

Install these in WSL Ubuntu terminal:

```bash
# 1. Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# 2. Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# 3. kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 4. Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 5. Ansible
sudo apt install python3-pip -y && pip3 install ansible

# 6. gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin
```

### External Accounts Required

| Service       | Purpose                            | Link                                                         |
| ------------- | ---------------------------------- | ------------------------------------------------------------ |
| GCP           | Cloud infrastructure               | [console.cloud.google.com](https://console.cloud.google.com) |
| MongoDB Atlas | Database (free tier)               | [cloud.mongodb.com](https://cloud.mongodb.com)               |
| CloudAMQP     | RabbitMQ (free tier)               | [cloudamqp.com](https://cloudamqp.com)                       |
| Cloudinary    | Image storage (free tier)          | [cloudinary.com](https://cloudinary.com)                     |
| Razorpay      | Indian payments (test mode)        | [razorpay.com](https://razorpay.com)                         |
| Stripe        | International payments (test mode) | [stripe.com](https://stripe.com)                             |
| DockerHub     | Container registry (free)          | [hub.docker.com](https://hub.docker.com)                     |
| DuckDNS       | Free domain                        | [duckdns.org](https://duckdns.org)                           |

---

## 💻 Local Development Setup

### Step 1: Clone the repository

```bash
git clone https://github.com/suryaparua-official/Swiggy.git
cd Swiggy-main
```

### Step 2: Create environment file

```bash
cp .env.example .env
```

Edit `.env` with your actual credentials:

```env
# Auth
JWT_SEC=your_random_secret_string_here
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Internal service communication
INTERNAL_SERVICE_KEY=your_random_internal_key

# Cloudinary (image storage)
CLOUD_NAME=your_cloudinary_cloud_name
CLOUD_API_KEY=your_cloudinary_api_key
CLOUD_SECRET_KEY=your_cloudinary_secret_key

# Payments
RAZORPAY_KEY_ID=rzp_test_xxxxx
RAZORPAY_KEY_SECRET=your_razorpay_secret
STRIPE_SECRET_KEY=sk_test_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx

# RabbitMQ (CloudAMQP)
RABBITMQ_URL=amqps://user:pass@host/vhost

# Queue names (do not change)
PAYMENT_QUEUE=payment_event
RIDER_QUEUE=rider_queue
ORDER_READY_QUEUE=order_ready_queue
```

### Step 3: Start all services

```bash
docker compose up --build
```

### Service URLs

| Service            | URL                                  |
| ------------------ | ------------------------------------ |
| Frontend           | http://localhost:3000                |
| Auth API           | http://localhost:5000                |
| Restaurant API     | http://localhost:5001                |
| Utils API          | http://localhost:5002                |
| Realtime           | http://localhost:5004                |
| Rider API          | http://localhost:5005                |
| Admin API          | http://localhost:5006                |
| RabbitMQ Dashboard | http://localhost:15672 (guest/guest) |

### Step 4: Google OAuth setup for local

In [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials → Your OAuth Client:

Add to **Authorised JavaScript origins:**

```
http://localhost:3000
http://localhost:5173
```

---

## ☁️ Cloud Deployment (GCP + GKE)

### Phase 1: Prepare GCP

```bash
# Login to GCP
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com

# Create Terraform state bucket (change name to be globally unique)
gcloud storage buckets create gs://your-unique-bucket-name \
  --location=asia-south1
```

### Phase 2: Configure Terraform

```bash
cd terraform/

# Create terraform.tfvars (never commit this file)
cat > terraform.tfvars << EOF
project_id   = "your-gcp-project-id"
github_org   = "your-github-username"
github_repo  = "Swiggy"
EOF

# Update main.tf — change bucket name to match what you created above
# backend "gcs" { bucket = "your-unique-bucket-name" }
```

### Phase 3: Provision Infrastructure

```bash
terraform init
terraform plan      # Review what will be created
terraform apply     # Type "yes" — takes ~10 minutes
```

**Note outputs after apply:**

```bash
terraform output workload_identity_provider   # → WIF_PROVIDER secret
terraform output github_actions_sa_email      # → GCP_SA_EMAIL secret
```

### Phase 4: Connect to Cluster

```bash
gcloud container clusters get-credentials swiggy-cluster \
  --zone asia-south1-a \
  --project YOUR_PROJECT_ID

# Verify connection
kubectl get nodes
```

### Phase 5: Create Static IP

```bash
gcloud compute addresses create swiggy-ip --global

# Get the IP address
gcloud compute addresses describe swiggy-ip --global --format="get(address)"
# Save this IP — you'll need it for DuckDNS and GitHub Secrets
```

### Phase 6: Setup Free Domain (DuckDNS)

1. Go to [duckdns.org](https://duckdns.org) → Login with Google
2. Create subdomain: `your-app-name` → full domain: `your-app-name.duckdns.org`
3. Enter your static IP from Step 5
4. Click **Update IP**


<img width="940" height="675" alt="Screenshot 2026-04-30 231325" src="https://github.com/user-attachments/assets/1de1959b-8684-4837-b1dc-634d6a5ac8f9" />


### Phase 7: Update k8s/managed-certificate.yml

```yaml
spec:
  domains:
    - your-app-name.duckdns.org # ← change to your domain
```

### Phase 8: Update k8s/argocd-app.yml

```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### Phase 9: Install Tools on Cluster

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.0/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s
kubectl apply -f k8s/argocd-app.yml

# Install Monitoring (Prometheus + Grafana + Loki)
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=your_secure_password \
  --set prometheus.prometheusSpec.retention=7d \
  --wait --timeout 300s

helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true \
  --wait --timeout 180s

# Install Tracing (Jaeger)
kubectl create namespace tracing
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm upgrade --install jaeger jaegertracing/jaeger \
  --namespace tracing \
  --set allInOne.enabled=true \
  --wait --timeout 180s
```

### Phase 10: Configure GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Add all these secrets:

| Secret Name              | Where to get it                                            |
| ------------------------ | ---------------------------------------------------------- |
| `DOCKERHUB_USERNAME`     | Your DockerHub username                                    |
| `DOCKERHUB_TOKEN`        | DockerHub → Account Settings → Security → Access Tokens    |
| `SNYK_TOKEN`             | [snyk.io](https://snyk.io) → Account Settings → Auth Token |
| `WIF_PROVIDER`           | `terraform output workload_identity_provider`              |
| `GCP_SA_EMAIL`           | `terraform output github_actions_sa_email`                 |
| `GKE_CLUSTER_NAME`       | `swiggy-cluster`                                           |
| `GKE_CLUSTER_LOCATION`   | `asia-south1-a`                                            |
| `MONGO_URI`              | MongoDB Atlas → Connect → Drivers → connection string      |
| `JWT_SEC`                | Any random long string                                     |
| `INTERNAL_SERVICE_KEY`   | Any random long string                                     |
| `GOOGLE_CLIENT_ID`       | Google Cloud Console → OAuth                               |
| `GOOGLE_CLIENT_SECRET`   | Google Cloud Console → OAuth                               |
| `CLOUD_NAME`             | Cloudinary dashboard                                       |
| `CLOUD_API_KEY`          | Cloudinary dashboard                                       |
| `CLOUD_SECRET_KEY`       | Cloudinary dashboard                                       |
| `RAZORPAY_KEY_ID`        | Razorpay dashboard                                         |
| `RAZORPAY_KEY_SECRET`    | Razorpay dashboard                                         |
| `STRIPE_SECRET_KEY`      | Stripe dashboard                                           |
| `STRIPE_PUBLISHABLE_KEY` | Stripe dashboard                                           |
| `RABBITMQ_URL`           | CloudAMQP → Instance → AMQP URL                            |
| `VITE_AUTH_URL`          | `https://your-domain.duckdns.org`                          |
| `VITE_RESTAURANT_URL`    | `https://your-domain.duckdns.org`                          |
| `VITE_UTILS_URL`         | `https://your-domain.duckdns.org`                          |
| `VITE_REALTIME_URL`      | `https://your-domain.duckdns.org`                          |
| `VITE_RIDER_URL`         | `https://your-domain.duckdns.org`                          |
| `VITE_ADMIN_URL`         | `https://your-domain.duckdns.org`                          |

### Phase 11: Google OAuth for Production

In Google Cloud Console → OAuth Client → Add:

**Authorised JavaScript origins:**

```
https://your-domain.duckdns.org
```

**Authorised redirect URIs:**

```
https://your-domain.duckdns.org
```

### Phase 12: Deploy

```bash
# Trigger the CI/CD pipeline
git add .
git commit -m "deploy: initial production deployment"
git push origin main
```

GitHub Actions will:

1. Build all 7 Docker images
2. Run Snyk + Trivy security scans
3. Push images to DockerHub
4. Update k8s manifests with new image tags
5. Create Kubernetes secrets from GitHub Secrets


<img width="950" height="537" alt="Screenshot 2026-04-30 232909" src="https://github.com/user-attachments/assets/b39d4b09-6224-48b8-9532-49a16f516144" />




ArgoCD will detect the manifest changes and deploy automatically.

### Phase 13: Apply Kubernetes Secrets Manually

> **Important:** After each CD run, re-apply real secrets (the CD pipeline uses GitHub Secrets but you should verify they applied correctly):

```bash
kubectl create secret generic swiggy-secrets \
  --namespace swiggy \
  --from-literal=MONGO_URI="your_mongo_uri" \
  --from-literal=JWT_SEC="your_jwt_secret" \
  --from-literal=RABBITMQ_URL="your_rabbitmq_url" \
  # ... add all other secrets
  --dry-run=client -o yaml | kubectl apply -f -
```

### Phase 14: Wait for SSL Certificate

```bash
# Check certificate status (takes 15-30 minutes)
kubectl describe managedcertificate swiggy-cert -n swiggy

# Status should show: Active
```

Once Active, your app is live at `https://your-domain.duckdns.org` ✅

---

## 🔄 CI/CD Pipeline

### CI Pipeline (`ci.yml`)

Triggers on push/PR to `main`:

```
1. Snyk dependency scan (all services)
2. Docker build (7 services in parallel)
3. Trivy image vulnerability scan (CRITICAL severity fails build)
4. Push to DockerHub (main branch only)
   - Tags: latest + git commit SHA
```

### CD Pipeline (`cd.yml`)

Triggers when CI succeeds:

```
1. Update image tags in k8s/*/deployment.yml
2. Commit and push to GitHub
3. Authenticate to GCP (Workload Identity Federation — no static keys)
4. Get GKE credentials
5. Create/update Kubernetes secrets from GitHub Secrets
```

ArgoCD detects the commit and performs rolling deployment with zero downtime.


<img width="1919" height="944" alt="Screenshot 2026-05-01 042509" src="https://github.com/user-attachments/assets/ac5f0888-c148-4095-9b3f-79836572360b" />

<img width="1919" height="951" alt="Screenshot 2026-05-01 042224" src="https://github.com/user-attachments/assets/213ec0f9-54b3-4b46-8764-0c8889258a1f" />



---

## 📊 Monitoring & Observability

### Access Monitoring Tools

All tools require port-forwarding (internal access only — production best practice):

```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8888:443 &
# URL: http://localhost:8888
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode

# Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring &
# URL: http://localhost:3000
# Username: admin / Password: (as configured during install)

# Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring &
# URL: http://localhost:9090

# Alertmanager
kubectl port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 -n monitoring &
# URL: http://localhost:9093

# Jaeger
kubectl port-forward svc/jaeger 16686:16686 -n tracing &
# URL: http://localhost:16686
```

### Grafana Dashboards


<img width="1919" height="937" alt="Screenshot 2026-05-01 043312" src="https://github.com/user-attachments/assets/791b3e73-9dfa-4c31-ae22-e881117c993f" />


<img width="1919" height="944" alt="Screenshot 2026-05-01 043545" src="https://github.com/user-attachments/assets/fc6eaa89-fcb0-4758-8d13-7f15d6d56105" />


Pre-installed dashboards (via kube-prometheus-stack):

- **Kubernetes / Compute Resources / Namespace (Pods)** — CPU/Memory per pod
- **Kubernetes / Compute Resources / Node (Pods)** — Node-level resources
- **Kubernetes / Networking / Namespace (Pods)** — Network I/O
- **Alertmanager / Overview** — Active alerts

### Useful Prometheus Queries


<img width="1919" height="982" alt="Screenshot 2026-05-01 042801" src="https://github.com/user-attachments/assets/49ff1079-9800-426e-83a9-989b8f184f76" />


```promql
# All pods running status
up

# CPU usage by pod in swiggy namespace
sum(rate(container_cpu_usage_seconds_total{namespace="swiggy"}[5m])) by (pod)

# Memory usage by pod
sum(container_memory_usage_bytes{namespace="swiggy"}) by (pod)

# HTTP request rate
rate(http_requests_total[5m])
```

### Loki Log Queries

In Grafana → Explore → Loki:

```logql
# All swiggy logs
{namespace="swiggy"}

# Auth service logs only
{namespace="swiggy", app="auth-service"}

# Error logs
{namespace="swiggy"} |= "error"

# RabbitMQ connection logs
{namespace="swiggy"} |= "RabbitMQ"
```

---

## 🚨 Alerting

### Slack Integration


<img width="961" height="877" alt="Screenshot 2026-05-01 051313" src="https://github.com/user-attachments/assets/5ffa99b3-fd0d-4964-a4ea-de57050d28b3" />


Configure Alertmanager to send alerts to Slack:

<img width="1369" height="945" alt="Screenshot 2026-05-01 044452" src="https://github.com/user-attachments/assets/32847bbb-9919-47f8-bb35-c92b1e4d6a0f" />

```bash
cat > /tmp/alertmanager.yml << 'EOF'
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

route:
  group_by: ['alertname', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'slack-notifications'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#your-alerts-channel'
        send_resolved: true
        title: '{{ .GroupLabels.alertname }}'
        text: >-
          *Alert:* {{ .GroupLabels.alertname }}
          *Severity:* {{ .CommonLabels.severity }}
          *Namespace:* {{ .GroupLabels.namespace }}
          *Summary:* {{ .CommonAnnotations.summary }}
EOF

kubectl create secret generic alertmanager-kube-prometheus-stack-alertmanager \
  --namespace monitoring \
  --from-file=alertmanager.yaml=/tmp/alertmanager.yml \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart statefulset/alertmanager-kube-prometheus-stack-alertmanager -n monitoring
```

### Default Alert Rules

The kube-prometheus-stack includes 100+ pre-built alert rules:

| Alert                            | Severity | Description                            |
| -------------------------------- | -------- | -------------------------------------- |
| `KubePodCrashLooping`            | critical | Pod restarting repeatedly              |
| `KubeDeploymentReplicasMismatch` | warning  | Deployment not at desired replicas     |
| `KubeCPUOvercommit`              | warning  | CPU requests exceed node capacity      |
| `KubeMemoryOvercommit`           | warning  | Memory requests exceed node capacity   |
| `Watchdog`                       | none     | Always fires — confirms alerting works |

---

## 🔐 Security

### Security measures implemented:

1. **Container security** — All containers run as non-root user
2. **Image scanning** — Trivy scans every Docker image in CI pipeline
3. **Dependency scanning** — Snyk scans all package.json files
4. **No static credentials** — GitHub Actions uses Workload Identity Federation
5. **Secrets management** — All secrets via Kubernetes Secrets, never in code
6. **Network isolation** — Pods in private subnet, Cloud NAT for outbound only
7. **HTTPS only** — GKE Managed Certificate with automatic renewal
8. **Internal service auth** — `x-internal-key` header for service-to-service calls
9. **JWT tokens** — 15-day expiry for user sessions

---

## 🌍 Environment Variables

### Root `.env` (for Docker Compose local development)

```env
JWT_SEC=                    # Random string for JWT signing
GOOGLE_CLIENT_ID=           # From Google Cloud Console
GOOGLE_CLIENT_SECRET=       # From Google Cloud Console
INTERNAL_SERVICE_KEY=       # Random string for internal auth
CLOUD_NAME=                 # Cloudinary cloud name
CLOUD_API_KEY=              # Cloudinary API key
CLOUD_SECRET_KEY=           # Cloudinary secret key
RAZORPAY_KEY_ID=            # Razorpay test key ID
RAZORPAY_KEY_SECRET=        # Razorpay test secret
STRIPE_SECRET_KEY=          # Stripe test secret key
STRIPE_PUBLISHABLE_KEY=     # Stripe test publishable key
RABBITMQ_URL=               # amqps://user:pass@host/vhost
PAYMENT_QUEUE=payment_event
RIDER_QUEUE=rider_queue
ORDER_READY_QUEUE=order_ready_queue
```

### Frontend `.env` (for local Vite dev server)

```env
VITE_AUTH_URL=http://localhost:5000
VITE_RESTAURANT_URL=http://localhost:5001
VITE_UTILS_URL=http://localhost:5002
VITE_REALTIME_URL=http://localhost:5004
VITE_RIDER_URL=http://localhost:5005
VITE_ADMIN_URL=http://localhost:5006
```

---

## 🛑 Destroying Infrastructure

When done testing, destroy all GCP resources to avoid charges:

```bash
cd terraform/
terraform destroy
# Type "yes"
```

**What gets destroyed:**

- GKE cluster and all nodes
- VPC network, subnet, NAT
- IAM service accounts and Workload Identity

**What does NOT get destroyed (delete manually if needed):**

- GCS bucket (Terraform state)
- Static IP (`gcloud compute addresses delete swiggy-ip --global`)

**Estimated cost:** ~$5-6 USD per day when running. $300 free credit on new GCP accounts.

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m "feat: add my feature"`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE.md](LICENSE.md)

---

## 👤 Author

**Surya Parua**

- GitHub: [@suryaparua-official](https://github.com/suryaparua-official)
- DockerHub: [surya850](https://hub.docker.com/u/surya850)
