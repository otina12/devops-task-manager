# Incident Response Runbook

Operational procedures for the Task Manager service. Objectives are defined in
[SLO.md](SLO.md).

## Quick reference

| Endpoint | URL |
|---|---|
| App | http://localhost:3000 |
| Grafana | http://localhost:3001 (admin/admin) |
| Prometheus | http://localhost:9090 |
| Alertmanager | http://localhost:9093 |
| Alert receiver | http://localhost:5001 |

| Action | Command |
|---|---|
| Validate environment | `make validate` |
| Smoke test | `make smoke` |
| Deploy (blue-green) | `make deploy` |
| Roll back | `make rollback` |
| Which slot is live | `cat deploy/active_slot` |

## Triage first

1. Check the alert in the receiver: http://localhost:5001 (or `docker logs alert-receiver`).
2. Run `make validate` to see which services are down/unhealthy.
3. Open the Grafana dashboard (request rate, p95 latency, 5xx, logs).

---

## Alert: AppInstanceDown

An app instance failed health scrapes for 30s.

1. `docker compose ps` — identify the unhealthy slot.
2. `docker logs app-blue` / `docker logs app-green` — look for crash/errors.
3. If the **inactive** slot is down: no user impact; rebuild it with `make deploy`.
4. If the **active** slot is down: `make rollback` to switch traffic to the healthy slot,
   then investigate the failed one.
5. `docker start <slot>` or `docker compose up -d <slot>` to restore it.

## Alert: HighErrorRate

5xx rate above threshold.

1. Grafana → "5xx Error Rate" panel and the Logs panel to find failing requests.
2. If it started right after a deploy, `make rollback` immediately.
3. Confirm recovery with `make smoke`.

## Alert: HighLatencyP95

p95 latency above 200 ms for 2m.

1. Grafana → latency panel; check cAdvisor/node-exporter for CPU/memory pressure.
2. Restart the affected slot if it is degraded: `docker restart app-<slot>`.
3. If caused by a deploy, `make rollback`.

---

## Failed deployment

`make deploy` runs a health check on the new slot, and a post-deploy **smoke test** after
the traffic switch. On smoke-test failure it **auto-rolls back** to the previous slot.

- If a deploy aborts at the health check: the new slot never received traffic; the old slot
  is still live. Inspect `docker logs app-<inactive>` and fix.
- If a deploy auto-rolled back after the smoke test: traffic is back on the old slot. Review
  the smoke output, fix the issue, and redeploy.

## Full recovery from scratch

```bash
make down
make up          # rebuilds and starts the whole stack
make validate    # confirm all services healthy
make smoke       # confirm functionality
```

## Self-healing built in

- Containers use `restart: unless-stopped` (auto-restart on crash/reboot).
- Each app container has a Docker `HEALTHCHECK`; nginx waits for healthy upstreams.
- The previous slot is always kept running for instant rollback.
