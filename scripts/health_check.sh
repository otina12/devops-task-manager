APP_URL="http://localhost:3000/health"
LOG_FILE="/opt/app/logs/health.log"
INTERVAL=60

mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Health monitor started" | tee -a "$LOG_FILE"

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  HTTP_CODE=$(curl -s -o /tmp/health_body -w "%{http_code}" --max-time 5 "$APP_URL" 2>/dev/null || echo "000")
  BODY=$(cat /tmp/health_body 2>/dev/null || echo "no response")

  if [ "$HTTP_CODE" == "200" ]; then
    echo "[$TIMESTAMP] UP | $BODY" | tee -a "$LOG_FILE"
  else
    echo "[$TIMESTAMP] DOWN (HTTP $HTTP_CODE) | $BODY" | tee -a "$LOG_FILE"
  fi

  sleep $INTERVAL
done
