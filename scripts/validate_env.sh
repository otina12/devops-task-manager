#!/usr/bin/env bash
set -e

echo "== Environment validation =="

command -v docker >/dev/null 2>&1 || { echo "FAIL: docker not installed"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "FAIL: docker compose not available"; exit 1; }
echo "  docker + compose present"

docker compose config -q && echo "  compose config valid"

FAIL=0
echo "== Services =="
for s in $(docker compose config --services); do
  cid=$(docker compose ps -q "$s" 2>/dev/null)
  if [ -z "$cid" ]; then
    echo "  [DOWN] $s (no container)"; FAIL=1; continue
  fi
  state=$(docker inspect --format '{{.State.Status}}' "$cid")
  health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cid")
  if [ "$state" != "running" ]; then
    echo "  [DOWN] $s ($state)"; FAIL=1
  elif [ "$health" = "unhealthy" ]; then
    echo "  [UNHEALTHY] $s"; FAIL=1
  else
    echo "  [OK] $s ($state/$health)"
  fi
done

echo "== App endpoint =="
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost:3000/health || echo 000)
if [ "$code" = "200" ]; then
  echo "  [OK] http://localhost:3000/health"
else
  echo "  [FAIL] /health returned $code"; FAIL=1
fi

if [ "$FAIL" = "0" ]; then
  echo "VALIDATION PASSED"
else
  echo "VALIDATION FAILED"; exit 1
fi
