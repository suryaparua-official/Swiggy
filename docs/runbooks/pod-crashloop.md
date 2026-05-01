# Runbook: Pod CrashLoopBackOff

## Symptoms

- Pod shows `CrashLoopBackOff` status
- `kubectl get pods -n swiggy` shows RESTARTS count increasing

## Diagnosis

```bash
# Step 1: Identify the crashing pod
kubectl get pods -n swiggy

# Step 2: Get logs from the crashed container
kubectl logs -n swiggy <pod-name> --previous

# Step 3: Describe the pod for events
kubectl describe pod -n swiggy <pod-name>
```

## Common Causes and Fixes

### Cause 1: Missing or wrong Kubernetes Secret

**Symptom in logs:**

```
Error: Expected amqp: or amqps: as the protocol; got
```

or

```
MongoServerError: bad auth
```

**Fix:**

```bash
# Verify secret values
kubectl get secret swiggy-secrets -n swiggy -o jsonpath='{.data.RABBITMQ_URL}' | base64 --decode
kubectl get secret swiggy-secrets -n swiggy -o jsonpath='{.data.MONGO_URI}' | base64 --decode

# If wrong, recreate the secret
kubectl delete secret swiggy-secrets -n swiggy
kubectl create secret generic swiggy-secrets \
  --namespace swiggy \
  --from-literal=MONGO_URI="your_actual_uri" \
  --from-literal=RABBITMQ_URL="your_actual_url" \
  # ... other secrets

# Restart the pod
kubectl rollout restart deployment/<service-name> -n swiggy
```

### Cause 2: RabbitMQ connection failure

**Symptom in logs:**

```
[RabbitMQ] Attempt 10/10 failed. Retrying in 3000ms...
```

**Fix:**

1. Check CloudAMQP dashboard — is the instance running?
2. Verify RABBITMQ_URL secret is correct
3. Check if RabbitMQ URL has expired or rotated

### Cause 3: Out of memory

**Symptom:** Pod killed with OOMKilled reason

**Fix:**

```bash
# Check resource usage
kubectl top pods -n swiggy

# Increase memory limits in deployment.yml
# resources:
#   limits:
#     memory: "512Mi"  # increase from 256Mi
```

### Cause 4: Missing /health endpoint

**Symptom:** Pod starts but liveness probe fails

**Fix:** Add health endpoint to the service's index.ts:

```typescript
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});
```

## Escalation

If the issue persists after trying all fixes:

1. Check GCP status page for regional incidents
2. Check MongoDB Atlas status
3. Check CloudAMQP status
4. Review recent deployments in ArgoCD
