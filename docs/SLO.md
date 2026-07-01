# Service Level Objectives (SLO)

These objectives define the reliability targets for the Task Manager service and how
they are measured. All metrics come from Prometheus (`/metrics` on each app instance).

## Objectives

| SLI | Objective | Measurement window |
|---|---|---|
| Availability | ≥ 99% of `/health` checks succeed | rolling 30 days |
| Latency | p95 request latency < 200 ms | rolling 5 min |
| Error rate | 5xx responses < 1% of requests | rolling 5 min |

## How each SLI is measured

**Availability** — Prometheus scrapes `up{job="app"}` for both slots every 15s.
```promql
avg_over_time(up{job="app"}[30d])
```

**Latency (p95)**
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

**Error rate**
```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))
```

## Error budget

A 99% availability target allows ~7.2 hours of downtime per 30 days. When the budget is
being consumed faster than expected (e.g. an alert firing), deployments should pause until
the service is stable and the cause is understood.

## Alerting

Objectives are backed by Prometheus alert rules
(`monitoring/prometheus/alert.rules.yml`), routed through Alertmanager to the local
alert receiver:

- `AppInstanceDown` — an instance fails health scrapes for 30s (availability).
- `HighErrorRate` — 5xx rate above threshold for 1m (error rate).
- `HighLatencyP95` — p95 latency above 200 ms for 2m (latency).

See [RUNBOOK.md](RUNBOOK.md) for the response to each.
