#!/usr/bin/env bash
set -e

BASE_URL="${1:-http://localhost:3000}"
TITLE="smoke-$(date +%s)"

echo "Smoke test against $BASE_URL"

fail() { echo "SMOKE FAIL: $1"; exit 1; }

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$BASE_URL/health" || echo 000)
[ "$code" = "200" ] || fail "health returned $code"
echo "  health OK"

resp=$(curl -s --max-time 5 -X POST "$BASE_URL/tasks" -H 'Content-Type: application/json' -d "{\"title\":\"$TITLE\"}")
id=$(echo "$resp" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
[ -n "$id" ] || fail "create did not return an id ($resp)"
echo "  create OK (id=$id)"

curl -s --max-time 5 "$BASE_URL/tasks" | grep -q "$TITLE" || fail "created task not found in list"
echo "  list OK"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -X PATCH "$BASE_URL/tasks/$id" || echo 000)
[ "$code" = "200" ] || fail "toggle returned $code"
echo "  toggle OK"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -X DELETE "$BASE_URL/tasks/$id" || echo 000)
[ "$code" = "204" ] || fail "delete returned $code"
echo "  delete OK"

echo "SMOKE PASS"
