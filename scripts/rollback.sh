set -e

APP_BASE="/opt/app"
BLUE_PORT=3001
GREEN_PORT=3002
NGINX_CONF="/etc/nginx/sites-available/taskmanager"

ACTIVE=$(cat "$APP_BASE/active_slot")
if [ "$ACTIVE" == "blue" ]; then
  ROLLBACK_TO="green"
  ROLLBACK_PORT=$GREEN_PORT
else
  ROLLBACK_TO="blue"
  ROLLBACK_PORT=$BLUE_PORT
fi

echo "============================================"
echo " Task Manager - Rollback"
echo "============================================"
echo " Current slot  : $ACTIVE"
echo " Rolling back  : $ROLLBACK_TO (port $ROLLBACK_PORT)"
echo "============================================"

# The rollback target must still be running
# deploy.sh intentionally leaves the old slot alive for this reason
if ! pm2 list | grep -q "app-$ROLLBACK_TO"; then
  echo "ERROR: app-$ROLLBACK_TO is not running. Nothing to roll back to."
  exit 1
fi

echo "--> Switching nginx back to $ROLLBACK_TO (port $ROLLBACK_PORT)..."
sudo bash -c "cat > $NGINX_CONF" <<EOF
upstream task_backend {
    server 127.0.0.1:$ROLLBACK_PORT;
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

echo "$ROLLBACK_TO" | sudo tee "$APP_BASE/active_slot" > /dev/null

echo "============================================"
echo " Rollback complete!"
echo " Live slot : $ROLLBACK_TO (port $ROLLBACK_PORT)"
echo "============================================"
