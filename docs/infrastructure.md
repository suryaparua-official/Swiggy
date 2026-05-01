# Infrastructure & Deployment Guide

Complete guide for cloud deployment on Google Cloud Platform (GCP) with Google Kubernetes Engine (GKE).

---

## Table of Contents

- [GCP Project Setup](#gcp-project-setup)
- [GKE Cluster Creation](#gke-cluster-creation)
- [Infrastructure as Code (Terraform)](#infrastructure-as-code)
- [Deployment Process](#deployment-process)
- [Networking & Load Balancing](#networking--load-balancing)
- [Storage & Databases](#storage--databases)
- [Security & IAM](#security--iam)
- [Monitoring & Logging](#monitoring--logging)
- [Scaling & Auto-Healing](#scaling--auto-healing)

---

## GCP Project Setup

### 1. Create GCP Project

```bash
gcloud projects create swiggy-prod --set-as-default
gcloud config set project swiggy-prod
```

### 2. Enable Required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicenetworking.googleapis.com \
  containerregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudkms.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com
```

### 3. Set Up Cloud Storage for Terraform State

```bash
gsutil mb gs://swiggy-terraform-state
gsutil versioning set on gs://swiggy-terraform-state
```

### 4. Create Service Account for Terraform

```bash
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

gcloud projects add-iam-policy-binding swiggy-prod \
  --member="serviceAccount:terraform-sa@swiggy-prod.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-sa@swiggy-prod.iam.gserviceaccount.com
```

---

## GKE Cluster Creation

### Manual GKE Setup (Alternative to Terraform)

```bash
# Create cluster
gcloud container clusters create swiggy-gke \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias \
  --enable-stackdriver-kubernetes \
  --enable-network-policy \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing

# Get cluster credentials
gcloud container clusters get-credentials swiggy-gke --zone us-central1-a
```

### Verify Cluster

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

---

## Infrastructure as Code

### Terraform Directory Structure

```
terraform/
├── main.tf          # Provider & backend config
├── variables.tf     # Variable definitions
├── vpc.tf          # VPC & networking
├── gke.tf          # GKE cluster config
├── iam.tf          # IAM roles & service accounts
├── outputs.tf      # Output values
└── terraform.tfvars # Variable values (secret)
```

### Main Configuration (main.tf)

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "swiggy-terraform-state"
    prefix = "prod"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
```

### VPC Configuration (vpc.tf)

```hcl
# Custom VPC
resource "google_compute_network" "vpc" {
  name                    = "swiggy-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "swiggy-subnet"
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.0.0/16"
}

# Cloud NAT for outbound traffic
resource "google_compute_router" "router" {
  name    = "swiggy-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "swiggy-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

### GKE Configuration (gke.tf)

```hcl
resource "google_container_cluster" "primary" {
  name            = "swiggy-gke"
  location        = var.gcp_zone
  network         = google_compute_network.vpc.name
  subnetwork      = google_compute_subnetwork.subnet.name

  # Cluster config
  initial_node_count       = 3
  remove_default_node_pool = true

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Monitoring
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  # Add-ons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
}

# Node pool for general workloads
resource "google_container_node_pool" "general" {
  name           = "general-pool"
  cluster        = google_container_cluster.primary.name
  node_count     = 2

  autoscaling {
    min_node_count = 2
    max_node_count = 8
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "n1-standard-2"

    disk_size_gb = 50

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
```

### IAM Configuration (iam.tf)

```hcl
# Service account for workloads
resource "google_service_account" "swiggy" {
  account_id   = "swiggy-sa"
  display_name = "Swiggy Service Account"
}

# IAM binding for Workload Identity
resource "google_service_account_iam_binding" "swiggy_iam" {
  service_account_id = google_service_account.swiggy.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[default/swiggy-ksa]"
  ]
}

# Roles for GCS, Cloud SQL, etc.
resource "google_project_iam_member" "cloudsql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.swiggy.email}"
}
```

### Terraform Commands

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan -var-file=terraform.tfvars

# Apply
terraform apply -var-file=terraform.tfvars

# Destroy (only in dev)
terraform destroy -var-file=terraform.tfvars
```

---

## Deployment Process

### 1. Build Docker Images

```bash
# Build all services
docker-compose build

# Tag for GCP Container Registry
docker tag swiggy-auth gcr.io/swiggy-prod/auth:latest
docker tag swiggy-restaurant gcr.io/swiggy-prod/restaurant:latest
docker tag swiggy-rider gcr.io/swiggy-prod/rider:latest
docker tag swiggy-utils gcr.io/swiggy-prod/utils:latest
docker tag swiggy-admin gcr.io/swiggy-prod/admin:latest
docker tag swiggy-realtime gcr.io/swiggy-prod/realtime:latest
docker tag swiggy-frontend gcr.io/swiggy-prod/frontend:latest

# Push to GCR
docker push gcr.io/swiggy-prod/auth:latest
docker push gcr.io/swiggy-prod/restaurant:latest
# ... push all images
```

### 2. Configure kubectl

```bash
gcloud container clusters get-credentials swiggy-gke --zone us-central1-a
kubectl config use-context gke_swiggy-prod_us-central1-a_swiggy-gke
```

### 3. Create Kubernetes Namespace

```bash
kubectl create namespace swiggy
kubectl label namespace swiggy environment=production
```

### 4. Set Up Secrets

```bash
# MongoDB connection string
kubectl create secret generic mongodb-secret \
  --from-literal=MONGODB_URI='mongodb+srv://user:pass@cluster.mongodb.net/swiggy' \
  -n swiggy

# JWT Secret
kubectl create secret generic jwt-secret \
  --from-literal=JWT_SECRET='your-super-secret-key' \
  -n swiggy

# Razorpay Keys
kubectl create secret generic razorpay-secret \
  --from-literal=RAZORPAY_KEY_ID='key_id' \
  --from-literal=RAZORPAY_SECRET='secret' \
  -n swiggy

# Google OAuth
kubectl create secret generic google-oauth-secret \
  --from-literal=GOOGLE_CLIENT_ID='client_id' \
  --from-literal=GOOGLE_CLIENT_SECRET='secret' \
  -n swiggy
```

### 5. Apply Kubernetes Manifests

```bash
# Apply in order
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/configmap.yml
kubectl apply -f k8s/*/deployment.yml
kubectl apply -f k8s/*/service.yml
kubectl apply -f k8s/ingress.yml
kubectl apply -f k8s/managed-certificate.yml
kubectl apply -f k8s/argocd-app.yml
```

### 6. Verify Deployment

```bash
# Check deployments
kubectl get deployments -n swiggy

# Check pods
kubectl get pods -n swiggy

# Check services
kubectl get svc -n swiggy

# Check ingress
kubectl get ingress -n swiggy

# View logs
kubectl logs -f deployment/restaurant-deployment -n swiggy
```

---

## Networking & Load Balancing

### Google Cloud Load Balancer (Ingress)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: swiggy-ingress
  namespace: swiggy
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.global-static-ip-name: "swiggy-ip"
    networking.gke.io/managed-certificates: "swiggy-cert"
spec:
  rules:
    - host: swiggy.example.com
      http:
        paths:
          - path: /api/auth/*
            pathType: ImplementationSpecific
            backend:
              service:
                name: auth-service
                port:
                  number: 5000
          - path: /api/restaurant/*
            pathType: ImplementationSpecific
            backend:
              service:
                name: restaurant-service
                port:
                  number: 5001
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### Managed Certificate

```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: swiggy-cert
  namespace: swiggy
spec:
  domains:
    - swiggy.example.com
    - www.swiggy.example.com
```

---

## Storage & Databases

### MongoDB Atlas

```bash
# Create cluster in MongoDB Atlas
# Connection string format:
mongodb+srv://username:password@cluster.mongodb.net/swiggy?retryWrites=true&w=majority

# Store in Kubernetes secret
kubectl create secret generic mongodb-secret \
  --from-literal=MONGODB_URI='connection_string' \
  -n swiggy
```

### Cloud Storage (for images, documents)

```bash
# Create bucket
gsutil mb gs://swiggy-media

# Create service account with access
gcloud iam service-accounts create swiggy-gcs
gcloud projects add-iam-policy-binding swiggy-prod \
  --member="serviceAccount:swiggy-gcs@swiggy-prod.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Bind to Kubernetes service account
kubectl annotate serviceaccount swiggy-ksa \
  iam.gke.io/gcp-service-account=swiggy-gcs@swiggy-prod.iam.gserviceaccount.com \
  -n swiggy
```

---

## Security & IAM

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: swiggy-network-policy
  namespace: swiggy
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector: {}
  egress:
    - to:
        - podSelector: {}
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 53 # DNS
        - protocol: UDP
          port: 53
```

### Pod Security Policy

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - configMap
    - emptyDir
    - projected
    - secret
    - downwardAPI
    - persistentVolumeClaim
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: MustRunAs
    seLinuxOptions:
      level: "s0:c123,c456"
```

---

## Monitoring & Logging

### Google Cloud Monitoring

```bash
# View metrics
gcloud monitoring dashboards list

# Create custom dashboard
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

### Prometheus & Grafana (Optional)

```bash
# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring
```

### Logging

```bash
# View logs from all pods
kubectl logs -f -l app=restaurant -n swiggy

# Stream logs to Cloud Logging
gcloud logging read "resource.type=k8s_container" --limit 50
```

---

## Scaling & Auto-Healing

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: restaurant-hpa
  namespace: swiggy
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: restaurant-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### Resource Requests & Limits

```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5001
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 5001
  initialDelaySeconds: 10
  periodSeconds: 5
```

---

## Disaster Recovery

### Backup Strategy

```bash
# Backup MongoDB Atlas
mongoexport --uri="mongodb+srv://user:pass@cluster.mongodb.net/swiggy" \
  --collection=users \
  --out=users.json

# Use MongoDB Ops Manager or cloud backup
```

### Kubernetes Backup

```bash
# Using Velero
velero backup create swiggy-backup-$(date +%Y%m%d)
```

---

## Cost Optimization

### Tips

1. **Use Preemptible VMs** - 70% cheaper but can be interrupted
2. **Right-size Node Pools** - Monitor and adjust machine types
3. **Enable Autoscaling** - Scale down unused nodes
4. **Use Committed Use Discounts** - GCP commitment pricing
5. **Image Optimization** - Reduce Docker image sizes
6. **Database Optimization** - Proper indexing in MongoDB

### Cost Monitoring

```bash
gcloud billing accounts list
gcloud compute instances list --filter="zone:us-central1-a"
gcloud container clusters describe swiggy-gke --zone=us-central1-a
```
