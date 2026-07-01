#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

SLOT_FILE="deploy/active_slot"
NGINX_CONF="nginx/conf.d/app.conf"

ACTIVE=$(cat "$SLOT_FILE" 2>/dev/null || echo blue)
if [ "$ACTIVE" == "blue" ]; then INACTIVE="green"; else INACTIVE="blue"; fi

echo "============================================"
echo " Task Manager - Docker Blue-Green Deploy"
echo "============================================"
echo " Active slot  : $ACTIVE"
echo " Deploying to : $INACTIVE"
echo "============================================"

echo "--> Building and recreating app-$INACTIVE..."
docker compose up -d --build --no-deps "app-$INACTIVE"

echo "--> Running health check..."
HEALTHY=false
for i in $(seq 1 10); do
  sleep 3
  STATUS=$(docker inspect --format '{{.State.Health.Status}}' "app-$INACTIVE" 2>/dev/null || echo "starting")
  if [ "$STATUS" == "healthy" ]; then
    echo "    Health check passed (attempt $i)"
    HEALTHY=true
    break
  fi
  echo "    Attempt $i: $STATUS"
done

if [ "$HEALTHY" != "true" ]; then
  echo "ERROR: app-$INACTIVE did not become healthy. Aborting deploy."
  exit 1
fi

echo "--> Switching nginx to app-$INACTIVE..."
sed -i.bak "s/server app-[a-z]*:3000;/server app-$INACTIVE:3000;/" "$NGINX_CONF"
rm -f "$NGINX_CONF.bak"
docker compose exec -T nginx nginx -s reload

echo "--> Running post-deploy smoke test..."
if ! bash "$REPO_DIR/scripts/smoke_test.sh" http://localhost:3000; then
  echo "ERROR: smoke test failed. Auto-rolling back to $ACTIVE..."
  sed -i.bak "s/server app-[a-z]*:3000;/server app-$ACTIVE:3000;/" "$NGINX_CONF"
  rm -f "$NGINX_CONF.bak"
  docker compose exec -T nginx nginx -s reload
  exit 1
fi

echo "$INACTIVE" > "$SLOT_FILE"

echo "============================================"
echo " Deploy complete!"
echo " Live slot : $INACTIVE"
echo " Old slot  : $ACTIVE kept running for rollback"
echo "============================================"
