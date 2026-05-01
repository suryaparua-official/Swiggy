# Operational Runbooks

Procedures for common operational scenarios and incident response.

---

## Table of Contents

- [Service Health Checks](#service-health-checks)
- [Pod CrashLoop Recovery](#pod-crashloop-recovery)
- [Database Issues](#database-issues)
- [Queue Backlog](#queue-backlog)
- [High Latency](#high-latency)
- [Memory Leaks](#memory-leaks)
- [Service Restart](#service-restart)
- [Data Recovery](#data-recovery)
- [Scaling Issues](#scaling-issues)
- [Network Troubleshooting](#network-troubleshooting)

---

## Service Health Checks

### Check All Services Status

```bash
# Get all pods status
kubectl get pods -n swiggy

# Expected output: All pods should be Running
# NAME                                    READY   STATUS    RESTARTS   AGE
# auth-deployment-abc123                  1/1     Running   0          5h
# restaurant-deployment-def456            1/1     Running   0          5h
# rider-deployment-ghi789                 1/1     Running   0          5h
```

### Individual Service Health

```bash
# Health endpoints
curl http://localhost:5000/health      # Auth
curl http://localhost:5001/health      # Restaurant
curl http://localhost:5002/health      # Utils
curl http://localhost:5004/health      # Realtime
curl http://localhost:5005/health      # Rider
curl http://localhost:5003/health      # Admin

# Expected response: 200 OK
# { "status": "healthy", "timestamp": "..." }
```

### Database Connectivity

```bash
# MongoDB health
mongosh --eval "db.adminCommand('ping')"

# RabbitMQ health
rabbitmq-diagnostics -q ping
```

---

## Pod CrashLoop Recovery

### Identify Crashed Pod

```bash
# Find crashing pods
kubectl get pods -n swiggy | grep CrashLoopBackOff

# Get pod details
kubectl describe pod <pod-name> -n swiggy
kubectl logs <pod-name> -n swiggy --previous  # Previous logs before crash
kubectl logs <pod-name> -n swiggy              # Current attempt logs
```

### Common CrashLoop Causes

**1. Database Connection Failed**

Logs show: `MONGODB_URI is required` or `Cannot connect to MongoDB`

**Solution:**

```bash
# Check MongoDB is running
mongosh --eval "db.adminCommand('ping')"

# Verify secret exists
kubectl get secret mongodb-secret -n swiggy

# Check secret values are correct
kubectl get secret mongodb-secret -n swiggy -o jsonpath='{.data.MONGODB_URI}'

# If secret is wrong, recreate it
kubectl delete secret mongodb-secret -n swiggy
kubectl create secret generic mongodb-secret \
  --from-literal=MONGODB_URI='correct-connection-string' \
  -n swiggy

# Restart pod
kubectl delete pod <pod-name> -n swiggy
```

**2. Port Already in Use**

Logs show: `EADDRINUSE: address already in use :::5001`

**Solution:**

```bash
# Check if multiple pods are running
kubectl get pods -n swiggy | grep restaurant

# Delete duplicate pods
kubectl delete pod <duplicate-pod> -n swiggy

# Verify only 1 replica running
kubectl get replicaset -n swiggy
```

**3. Out of Memory**

Logs show: `JavaScript heap out of memory` or `ENOMEM`

**Solution:**

```bash
# Check current memory limits
kubectl get deployment restaurant-deployment -n swiggy -o yaml | grep -A 10 resources

# Increase memory limits
kubectl set resources deployment restaurant-deployment \
  --limits=memory=2Gi \
  --requests=memory=1Gi \
  -n swiggy

# Restart deployment
kubectl rollout restart deployment/restaurant-deployment -n swiggy
```

**4. Environment Variables Missing**

Logs show: `Error: Required environment variable X is not set`

**Solution:**

```bash
# Check ConfigMap
kubectl get configmap -n swiggy
kubectl get configmap app-config -n swiggy -o yaml

# Check environment in deployment
kubectl get deployment restaurant-deployment -n swiggy -o yaml | grep -A 20 env

# Update ConfigMap if needed
kubectl edit configmap app-config -n swiggy

# Restart to pick up new env vars
kubectl rollout restart deployment/restaurant-deployment -n swiggy
```

---

## Database Issues

### MongoDB Connection Pool Exhausted

**Symptoms:** Timeouts in logs, requests hanging, `MongoServerError: connection timeout`

```bash
# Check connection pool status
mongosh
> db.serverStatus().connections
# {
#   "current": 45,
#   "available": 955,
#   "totalCreated": 1000
# }
```

**Solution:**

```bash
# 1. Check how many services are connecting
kubectl logs -l app=restaurant -n swiggy | grep "connection" | tail -20

# Restart service to release stale connections
kubectl rollout restart deployment/restaurant-deployment -n swiggy

# 3. Update connection pool settings in deployment
kubectl set env deployment/restaurant-deployment \
  MONGODB_POOL_SIZE=50 \
  MONGODB_MAX_IDLE_TIME=30000 \
  -n swiggy

# 4. Restart MongoDB Atlas cluster if needed
# In MongoDB Atlas console:
# Cluster → Pause → Resume
```

### MongoDB Disk Full

**Symptoms:** Write operations fail, "Out of space" errors

```bash
# Check database size
mongosh
> db.stats()
> db.collection_name.stats()

# Clean up old documents
db.orders.deleteMany({
  createdAt: { $lt: new Date(Date.now() - 90*24*60*60*1000) }
})
```

---

## Queue Backlog

### Monitor Queue Depth

```bash
# Via RabbitMQ CLI
rabbitmqctl list_queues name messages consumers

# Via Management UI
# http://localhost:15672 → Queues tab

# Expected: Most queues should have 0-5 messages
```

### High Queue Backlog

**Symptoms:** Queue "messages_ready" count is growing, not decreasing

```bash
# Check if consumer is running
kubectl logs deployment/restaurant-deployment -n swiggy | grep "Consuming"

# Verify RabbitMQ is accessible
kubectl exec -it <pod-name> -n swiggy -- \
  rabbitmqadmin list queue_bindings

# Restart consumer service
kubectl rollout restart deployment/restaurant-deployment -n swiggy

# Scale up consumers
kubectl scale deployment/restaurant-deployment --replicas=5 -n swiggy

# Monitor queue depth
watch 'rabbitmqctl list_queues name messages'
```

---

## High Latency

### Identify Slow Endpoints

```bash
# Check logs for slow requests
kubectl logs -f deployment/restaurant-deployment -n swiggy | grep "duration"

# Profile with async_hooks
kubectl exec -it <pod-name> -n swiggy -- \
  node --prof-process isolate-*.log > profile.txt
```

### Common Causes & Solutions

**1. Database Query Slow**

```bash
# Check indexes
mongosh
> db.orders.getIndexes()

# Add missing indexes
db.orders.createIndex({ customerId: 1, createdAt: -1 })
db.orders.createIndex({ restaurantId: 1, orderStatus: 1 })
```

**2. N+1 Query Problem**

- Join data in aggregation pipeline instead of fetching separately
- Use `$lookup` operator in MongoDB

**3. High CPU Usage**

```bash
# Check CPU metrics
kubectl top pods -n swiggy
kubectl top nodes

# If CPU high, scale up replicas
kubectl scale deployment/restaurant-deployment --replicas=5 -n swiggy
```

---

## Memory Leaks

### Detect Memory Leak

```bash
# Monitor memory over time
kubectl top pods -n swiggy --containers

# If memory keeps growing, restart
kubectl delete pod <pod-name> -n swiggy

# Check logs before restart
kubectl logs <pod-name> -n swiggy > /tmp/logs.txt
```

### Generate Heap Dump

```bash
# From Node.js process
kubectl exec -it <pod-name> -n swiggy -- \
  kill -USR2 <pid>

# Copy heap dump
kubectl cp swiggy/<pod-name>:/app/heapdump* /tmp/

# Analyze with Chrome DevTools
# chrome://inspect → Open dedicated DevTools for Node
```

---

## Service Restart

### Graceful Restart

```bash
# For single service
kubectl rollout restart deployment/restaurant-deployment -n swiggy

# For all services
kubectl rollout restart deployment -n swiggy

# Check status
kubectl rollout status deployment/restaurant-deployment -n swiggy
```

### Hard Restart (if graceful fails)

```bash
# Delete and recreate pods
kubectl delete pods -l app=restaurant -n swiggy

# Verify new pods start
kubectl get pods -n swiggy -w
```

---

## Data Recovery

### MongoDB Backup Restore

```bash
# List backups in Atlas
# MongoDB Atlas → Backup tab

# Restore from snapshot
# Click snapshot → "Restore" → Choose destination

# Manual backup
mongoexport --uri="mongodb+srv://..." \
  --collection=orders \
  --out=orders.backup.json

# Restore from backup
mongoimport --uri="mongodb+srv://..." \
  --collection=orders \
  --file=orders.backup.json
```

### Kubernetes Deployment Restore

```bash
# View rollout history
kubectl rollout history deployment/restaurant-deployment -n swiggy

# Rollback to previous version
kubectl rollout undo deployment/restaurant-deployment -n swiggy

# Rollback to specific revision
kubectl rollout undo deployment/restaurant-deployment --to-revision=3 -n swiggy

# Check rollout status
kubectl rollout status deployment/restaurant-deployment -n swiggy
```

---

## Scaling Issues

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment/restaurant-deployment --replicas=5 -n swiggy

# Verify scaling
kubectl get pods -n swiggy | grep restaurant
```

### Horizontal Pod Autoscaler (HPA) Issues

```bash
# Check HPA status
kubectl get hpa -n swiggy
kubectl describe hpa restaurant-hpa -n swiggy

# If HPA stuck, delete and recreate
kubectl delete hpa restaurant-hpa -n swiggy
kubectl apply -f k8s/hpa/restaurant-hpa.yml

# View HPA metrics
kubectl get hpa restaurant-hpa -n swiggy --watch
```

### Node Scaling

```bash
# Check node pool
gcloud container node-pools list --cluster=swiggy-gke --zone=us-central1-a

# Scale node pool
gcloud container clusters resize swiggy-gke \
  --num-nodes=5 \
  --zone=us-central1-a

# Or set autoscaling
gcloud container clusters update swiggy-gke \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=10 \
  --zone=us-central1-a
```

---

## Network Troubleshooting

### Check Connectivity

```bash
# DNS resolution
kubectl exec -it <pod-name> -n swiggy -- \
  nslookup mongodb.example.com

# Ping test
kubectl exec -it <pod-name> -n swiggy -- \
  ping -c 3 10.0.0.1

# Port connectivity
kubectl exec -it <pod-name> -n swiggy -- \
  nc -zv mongodb 27017
```

### Network Policy Issues

```bash
# Check network policies
kubectl get networkpolicies -n swiggy

# If blocked, allow traffic
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
  namespace: swiggy
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
EOF

# Remove overly restrictive policies
kubectl delete networkpolicy <policy-name> -n swiggy
```

### Load Balancer Issues

```bash
# Check ingress
kubectl get ingress -n swiggy
kubectl describe ingress swiggy-ingress -n swiggy

# Check service endpoints
kubectl get endpoints -n swiggy
kubectl describe svc restaurant-service -n swiggy

# Test service internally
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n swiggy -- \
  curl http://restaurant-service:5001/health
```

---

## Incident Response Checklist

### During Incident

- [ ] Page on-call engineer
- [ ] Create incident channel
- [ ] Identify affected service
- [ ] Get baseline metrics (before incident)
- [ ] Check recent deployments
- [ ] Check error logs
- [ ] Check performance metrics

### Recovery Steps

1. **Gather Information**
   - What's broken?
   - How long has it been broken?
   - When did it last work?
   - What changed?

2. **Quick Wins**
   - Restart service
   - Scale up resources
   - Clear queues

3. **Mitigation**
   - Rollback recent changes
   - Route traffic elsewhere
   - Disable feature causing issue

4. **Root Cause Analysis (Post-Incident)**
   - Review logs
   - Check metrics
   - Document findings
   - Plan prevention

---

## Useful Commands Reference

```bash
# Get all resources
kubectl get all -n swiggy

# Watch deployments
kubectl get deployment -n swiggy -w

# Stream logs
kubectl logs -f deployment/restaurant-deployment -n swiggy

# Port forward
kubectl port-forward svc/restaurant-service 5001:5001 -n swiggy

# Execute in pod
kubectl exec -it <pod> -n swiggy -- bash

# Copy files
kubectl cp swiggy/<pod>:/app/logs /tmp/logs
kubectl cp /tmp/file swiggy/<pod>:/app/

# Describe resource
kubectl describe pod <pod-name> -n swiggy
```
