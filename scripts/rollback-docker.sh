#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

SLOT_FILE="deploy/active_slot"
NGINX_CONF="nginx/conf.d/app.conf"

ACTIVE=$(cat "$SLOT_FILE" 2>/dev/null || echo blue)
if [ "$ACTIVE" == "blue" ]; then TARGET="green"; else TARGET="blue"; fi

echo "============================================"
echo " Task Manager - Docker Rollback"
echo "============================================"
echo " Current slot : $ACTIVE"
echo " Rolling back : $TARGET"
echo "============================================"

if ! docker inspect --format '{{.State.Running}}' "app-$TARGET" 2>/dev/null | grep -q true; then
  echo "ERROR: app-$TARGET is not running. Nothing to roll back to."
  exit 1
fi

echo "--> Switching nginx back to app-$TARGET..."
sed -i.bak "s/server app-[a-z]*:3000;/server app-$TARGET:3000;/" "$NGINX_CONF"
rm -f "$NGINX_CONF.bak"
docker compose exec -T nginx nginx -s reload

echo "$TARGET" > "$SLOT_FILE"

echo "============================================"
echo " Rollback complete!"
echo " Live slot : $TARGET"
echo "============================================"
