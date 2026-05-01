# Service Level Objectives (SLOs)

## Overview

This document defines the Service Level Objectives for the Swiggy food delivery platform.

## SLO Definitions

### Availability SLOs

| Service            | Target Availability | Error Budget (30 days) |
| ------------------ | ------------------- | ---------------------- |
| Frontend           | 99.5%               | 3.6 hours downtime     |
| Auth Service       | 99.5%               | 3.6 hours downtime     |
| Restaurant Service | 99.5%               | 3.6 hours downtime     |
| Payment (Utils)    | 99.9%               | 43.2 minutes downtime  |
| Realtime Service   | 99.0%               | 7.2 hours downtime     |

### Latency SLOs

| Service           | p50     | p95     | p99  |
| ----------------- | ------- | ------- | ---- |
| Auth API          | < 200ms | < 500ms | < 1s |
| Restaurant search | < 300ms | < 800ms | < 2s |
| Payment create    | < 500ms | < 1s    | < 3s |

### Error Rate SLOs

| Service         | Max Error Rate     |
| --------------- | ------------------ |
| All services    | < 1% of requests   |
| Payment service | < 0.1% of requests |

## Error Budget Policy

- **> 50% budget consumed:** Engineering team reviews
- **> 75% budget consumed:** Feature freeze, focus on reliability
- **100% budget consumed:** Post-mortem required, escalation to management

## Prometheus Queries for SLO Monitoring

```promql
# Availability: fraction of time service is up
avg_over_time(up{namespace="swiggy"}[30d])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])
  /
rate(http_requests_total[5m])

# p95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```
