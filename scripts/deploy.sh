set -e

APP_BASE="/opt/app"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BLUE_PORT=3001
GREEN_PORT=3002
NGINX_CONF="/etc/nginx/sites-available/taskmanager"

ACTIVE=$(cat "$APP_BASE/active_slot")
if [ "$ACTIVE" == "blue" ]; then
  INACTIVE="green"
  NEW_PORT=$GREEN_PORT
else
  INACTIVE="blue"
  NEW_PORT=$BLUE_PORT
fi

echo "============================================"
echo " Task Manager - Blue-Green Deploy"
echo "============================================"
echo " Active slot  : $ACTIVE"
echo " Deploying to : $INACTIVE (port $NEW_PORT)"
echo "============================================"

echo "--> Syncing code to $INACTIVE slot..."
rsync -a --delete \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='scripts' \
  --exclude='ansible' \
  --exclude='nginx' \
  "$REPO_DIR/" "$APP_BASE/$INACTIVE/"

echo "--> Installing dependencies..."
cd "$APP_BASE/$INACTIVE"
npm ci --omit=dev

# pm2 delete is allowed to fail if the process doesn't exist yet
echo "--> Starting app-$INACTIVE on port $NEW_PORT..."
pm2 delete "app-$INACTIVE" 2>/dev/null || true
PORT=$NEW_PORT pm2 start app/server.js --name "app-$INACTIVE"
pm2 save

echo "--> Running health check..."
HEALTHY=false
for i in {1..5}; do
  sleep 3
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:$NEW_PORT/health" || echo "000")
  if [ "$HTTP_CODE" == "200" ]; then
    echo "    Health check passed (attempt $i)"
    HEALTHY=true
    break
  fi
  echo "    Attempt $i: got HTTP $HTTP_CODE, retrying..."
done

if [ "$HEALTHY" != "true" ]; then
  echo "ERROR: Health check failed after 5 attempts. Aborting deploy."
  pm2 delete "app-$INACTIVE" 2>/dev/null || true
  exit 1
fi

echo "--> Switching nginx to $INACTIVE (port $NEW_PORT)..."
sudo bash -c "cat > $NGINX_CONF" <<EOF
upstream task_backend {
    server 127.0.0.1:$NEW_PORT;
}

server {
    listen 3000;
    server_name localhost;

    access_log /opt/app/logs/nginx_access.log;
    error_log  /opt/app/logs/nginx_error.log;

    location / {
        proxy_pass         http://task_backend;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo nginx -t
sudo systemctl reload nginx

echo "$INACTIVE" | sudo tee "$APP_BASE/active_slot" > /dev/null

echo "============================================"
echo " Deploy complete!"
echo " Live slot : $INACTIVE (port $NEW_PORT)"
echo " Old slot  : $ACTIVE kept running for rollback"
echo "============================================"
