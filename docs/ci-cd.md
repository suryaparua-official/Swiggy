# CI/CD Pipeline Documentation

Complete guide to GitHub Actions CI/CD pipeline for Swiggy.

---

## Table of Contents

- [Pipeline Overview](#pipeline-overview)
- [Continuous Integration (CI)](#continuous-integration-ci)
- [Continuous Deployment (CD)](#continuous-deployment-cd)
- [Deployment Environments](#deployment-environments)
- [Secrets Management](#secrets-management)
- [Monitoring Deployments](#monitoring-deployments)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)

---

## Pipeline Overview

**GitHub Actions Workflows:**

```
.github/workflows/
├── ci.yml      # Runs on every push/PR
└── cd.yml      # Runs on merge to main
```

### CI/CD Flow

```
Developer Push
    ↓
GitHub Actions Trigger
    ↓
Run CI Tests
  - Lint
  - Type Check
  - Unit Tests
  - Integration Tests
    ↓
  ├─ PASS → Merge to main
  │         ↓
  │   Run CD Pipeline
  │     - Build Docker images
  │     - Push to GCR
  │     - Update K8s manifests
  │     - Deploy to GKE
  │         ↓
  │   Health checks
  │   Smoke tests
  │         ↓
  │   ✅ Live in Production
  │
  └─ FAIL → Notify developer
            Block merge
```

---

## Continuous Integration (CI)

### CI Workflow (.github/workflows/ci.yml)

```yaml
name: CI Pipeline

on:
  push:
    branches: [develop, feature/*, bugfix/*]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x, 20.x]

    services:
      mongodb:
        image: mongo:7
        options: >-
          --health-cmd mongosh
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 27017:27017

      rabbitmq:
        image: rabbitmq:3.13
        options: >-
          --health-cmd rabbitmq-diagnostics -q ping
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5672:5672

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Lint code
        run: npm run lint

      - name: Type check
        run: npm run type-check

      - name: Run tests
        run: npm run test -- --coverage
        env:
          MONGODB_URI: mongodb://localhost:27017/swiggy-test
          RABBITMQ_URL: amqp://guest:guest@localhost:5672

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json

  build:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - uses: actions/checkout@v4

      - name: Build Docker images
        run: docker-compose build

      - name: Run security scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: swiggy-auth:latest
          format: "sarif"
          output: "trivy-results.sarif"

      - name: Upload scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: "trivy-results.sarif"

  frontend:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18.x
          cache: "npm"

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: Run Vitest
        working-directory: ./frontend
        run: npm run test

      - name: Upload build
        uses: actions/upload-artifact@v3
        with:
          name: frontend-build
          path: frontend/dist
          retention-days: 7
```

### Test Coverage Requirements

- **Overall coverage:** ≥ 80%
- **Critical paths:** ≥ 90%
- **Utilities:** ≥ 85%

---

## Continuous Deployment (CD)

### CD Workflow (.github/workflows/cd.yml)

```yaml
name: CD Pipeline

on:
  push:
    branches: [main]
    paths:
      - "services/**"
      - "frontend/**"
      - "k8s/**"
      - ".github/workflows/cd.yml"

env:
  GCP_PROJECT: swiggy-prod
  GKE_CLUSTER: swiggy-gke
  GKE_ZONE: us-central1-a
  REGISTRY: gcr.io

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    strategy:
      matrix:
        service: [auth, restaurant, rider, utils, admin, realtime]

    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          workload_identity_provider: ${{ secrets.WIP }}
          service_account: ${{ secrets.GCP_SA_EMAIL }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1

      - name: Configure Docker
        run: |
          gcloud auth configure-docker ${{ env.REGISTRY }}

      - name: Build Docker image
        run: |
          docker build \
            -t ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/${{ matrix.service }}:${{ github.sha }} \
            -t ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/${{ matrix.service }}:latest \
            -f services/${{ matrix.service }}/Dockerfile \
            .

      - name: Push to Google Container Registry
        run: |
          docker push ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/${{ matrix.service }}:${{ github.sha }}
          docker push ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/${{ matrix.service }}:latest

      - name: Image scan with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/${{ matrix.service }}:${{ github.sha }}
          format: "table"
          exit-code: "1"
          ignore-unfixed: true
          severity: "CRITICAL,HIGH"

  build-frontend:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18.x
          cache: "npm"

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          workload_identity_provider: ${{ secrets.WIP }}
          service_account: ${{ secrets.GCP_SA_EMAIL }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1

      - name: Configure Docker
        run: gcloud auth configure-docker ${{ env.REGISTRY }}

      - name: Build and push frontend image
        run: |
          docker build \
            -t ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/frontend:${{ github.sha }} \
            -t ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/frontend:latest \
            -f frontend/Dockerfile \
            frontend/

          docker push ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/frontend:${{ github.sha }}
          docker push ${{ env.REGISTRY }}/${{ env.GCP_PROJECT }}/frontend:latest

  deploy:
    runs-on: ubuntu-latest
    needs: [build-and-push, build-frontend]
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          workload_identity_provider: ${{ secrets.WIP }}
          service_account: ${{ secrets.GCP_SA_EMAIL }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1

      - name: Get GKE credentials
        run: |
          gcloud container clusters get-credentials ${{ env.GKE_CLUSTER }} \
            --zone ${{ env.GKE_ZONE }}

      - name: Update image tags in manifests
        run: |
          # Update all deployment manifests with new image tags
          find k8s -name "deployment.yml" -exec sed -i "s/:latest/:${{ github.sha }}/g" {} \;

      - name: Deploy to GKE
        run: |
          kubectl apply -f k8s/namespace.yml
          kubectl apply -f k8s/configmap.yml
          kubectl apply -f k8s/

      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/auth-deployment -n swiggy --timeout=5m
          kubectl rollout status deployment/restaurant-deployment -n swiggy --timeout=5m
          kubectl rollout status deployment/rider-deployment -n swiggy --timeout=5m
          kubectl rollout status deployment/utils-deployment -n swiggy --timeout=5m
          kubectl rollout status deployment/realtime-deployment -n swiggy --timeout=5m

  smoke-tests:
    runs-on: ubuntu-latest
    needs: deploy

    steps:
      - uses: actions/checkout@v4

      - name: Wait for services
        run: sleep 30

      - name: Health checks
        run: |
          for service in auth restaurant rider utils realtime; do
            response=$(curl -s -o /dev/null -w "%{http_code}" https://api.swiggy.example.com/health)
            if [ $response != "200" ]; then
              echo "Health check failed for $service"
              exit 1
            fi
          done

      - name: Basic API tests
        run: |
          # Test authentication endpoint
          curl -X POST https://api.swiggy.example.com/api/auth/login \
            -H "Content-Type: application/json" \
            -d '{"email":"test@example.com","password":"test"}'

  notify:
    runs-on: ubuntu-latest
    needs: smoke-tests
    if: always()

    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment Status: ${{ job.status }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Swiggy Deployment*\nStatus: ${{ job.status }}\nCommit: ${{ github.sha }}\nBranch: ${{ github.ref }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Deployment Environments

### Environments

| Environment     | Branch  | URL                        | Auto-deploy             |
| --------------- | ------- | -------------------------- | ----------------------- |
| **Development** | develop | dev.swiggy.local           | Yes                     |
| **Staging**     | staging | staging.swiggy.example.com | Yes                     |
| **Production**  | main    | swiggy.example.com         | Yes (after smoke tests) |

### Environment Variables by Stage

**Development:**

```env
NODE_ENV=development
LOG_LEVEL=debug
DEBUG=*
```

**Staging:**

```env
NODE_ENV=staging
LOG_LEVEL=info
```

**Production:**

```env
NODE_ENV=production
LOG_LEVEL=warn
```

---

## Secrets Management

### Required Secrets in GitHub

```
GCP_SA_EMAIL              # Service account email
WIP                       # Workload Identity Provider
SLACK_WEBHOOK             # Slack notifications
MONGODB_URI               # Database connection
JWT_SECRET                # JWT signing key
RAZORPAY_KEY_ID          # Razorpay credentials
RAZORPAY_SECRET          # Razorpay credentials
GOOGLE_CLIENT_ID         # OAuth credentials
GOOGLE_CLIENT_SECRET     # OAuth credentials
```

### Adding Secrets

```bash
# Via GitHub CLI
gh secret set SECRET_NAME --body "secret_value"

# Or in GitHub UI
Settings → Secrets and variables → Actions
```

---

## Monitoring Deployments

### GitHub Actions Dashboard

- View workflow runs: Actions tab in GitHub
- Real-time logs available for debugging
- Artifact downloads for builds

### Deployment Status Page

- Set up GitHub status page: https://status.github.com
- Link to deployment status in Slack

### Rollout Monitoring

```bash
# Check deployment status
kubectl rollout status deployment/auth-deployment -n swiggy

# View replica status
kubectl get replicaset -n swiggy

# Check pod events
kubectl describe pod <pod-name> -n swiggy
```

---

## Rollback Procedures

### Automatic Rollback (Failed Health Checks)

If smoke tests fail:

```yaml
steps:
  - name: Rollback on failure
    if: failure()
    run: |
      kubectl rollout undo deployment/auth-deployment -n swiggy
      kubectl rollout undo deployment/restaurant-deployment -n swiggy
      # ... undo all deployments
```

### Manual Rollback

```bash
# View rollout history
kubectl rollout history deployment/restaurant-deployment -n swiggy

# Rollback to previous version
kubectl rollout undo deployment/restaurant-deployment -n swiggy

# Rollback to specific revision
kubectl rollout undo deployment/restaurant-deployment -n swiggy --to-revision=3

# Check rollout status
kubectl rollout status deployment/restaurant-deployment -n swiggy
```

### Full Environment Rollback

```bash
# If entire deployment needs rollback
git revert <commit-hash>
git push origin main

# GitHub Actions will automatically re-deploy previous version
```

---

## Troubleshooting

### Pipeline Failures

**1. Test Failures**

```bash
# View detailed logs
gh run view <run-id> --log

# Rerun failed job
gh run rerun <run-id> --failed
```

**2. Docker Build Failure**

- Check Dockerfile syntax
- Verify base image availability
- Ensure all dependencies are listed

**3. Deployment Fails**

- Check Kubernetes manifest syntax: `kubectl apply --dry-run=client -f file.yml`
- Verify image exists in GCR
- Check cluster resources: `kubectl top nodes`

**4. Health Check Timeout**

- Increase timeout in CI/CD workflow
- Check application startup time
- Verify health endpoint is working

### Debugging

```bash
# View GitHub Actions logs
gh run view <run-id> --log

# List recent runs
gh run list --limit 10

# Get more details about workflow
gh workflow view <workflow-name>
```

---

## Best Practices

1. **Small commits** - Easier to debug and rollback
2. **Meaningful PR descriptions** - Document changes
3. **Require reviews** - Catch issues before merge
4. **Protect main branch** - Enforce CI/CD checks
5. **Monitor logs** - Watch deployments in real-time
6. **Test staging first** - Catch issues before production
7. **Document runbooks** - Easy incident response
8. **Regular backups** - Before major deployments

---

## Integration with Other Tools

### Slack Integration

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  if: always()
```

### Email Notifications

Configure in GitHub Settings → Notifications

### Grafana Alerts

Set alerts to trigger on deployment metrics

---

## Cost Optimization

- **GitHub Actions:** Free for public repos, ~$0.008/minute for private
- **GCP Container Registry:** Free tier + storage costs
- **Monitor:** Check Actions usage under Settings
