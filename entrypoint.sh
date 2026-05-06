#!/bin/sh
set -e

export N8N_PORT=${PORT:-5678}
export N8N_USER_FOLDER=${N8N_USER_FOLDER:-/data/n8n}

echo "[bundle] ============================================"
echo "[bundle] n8n Ecom Bundle starting"
echo "[bundle] PORT=$N8N_PORT"
echo "[bundle] N8N_USER_FOLDER=$N8N_USER_FOLDER"
echo "[bundle] ============================================"

mkdir -p "$N8N_USER_FOLDER"
chmod -R 777 "$N8N_USER_FOLDER"

IMPORTED_FLAG="$N8N_USER_FOLDER/.workflows-imported"

# Railway containers block loopback (127.0.0.1 and ::1 both give conn_refused).
# n8n binds to :: which covers all interfaces including eth0.
# Use the container's real eth0 IP so curl can actually reach n8n.
SELF_IP=$(ip -4 addr show scope global 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
[ -z "$SELF_IP" ] && SELF_IP=$(hostname -i 2>/dev/null | awk '{print $1}')
[ -z "$SELF_IP" ] && SELF_IP="127.0.0.1"
echo "[bundle] Container IP: $SELF_IP"

echo "[bundle] Checking import flag: $IMPORTED_FLAG"
if [ -f "$IMPORTED_FLAG" ]; then
  echo "[bundle] Flag exists — workflows already imported. Skipping import."
else
  echo "[bundle] Flag does not exist — will import after owner setup."
fi

echo "[bundle] Starting n8n on port $N8N_PORT..."
n8n start &
N8N_PID=$!
echo "[bundle] n8n started with PID $N8N_PID"

# Forward SIGTERM/SIGINT to n8n
trap "echo '[bundle] Caught signal, shutting down n8n...'; kill $N8N_PID; exit" TERM INT

if [ ! -f "$IMPORTED_FLAG" ]; then
  echo "[bundle] ---- Phase 1: Waiting for n8n HTTP to be ready ----"
  ATTEMPT=0
  until curl -sf "http://$SELF_IP:$N8N_PORT/healthz" > /dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://$SELF_IP:$N8N_PORT/healthz" 2>/dev/null || echo "conn_refused")
    echo "[bundle] Health check attempt $ATTEMPT — http://$SELF_IP:$N8N_PORT/healthz — HTTP $HTTP_CODE — retrying in 3s..."
    sleep 3
  done
  echo "[bundle] n8n HTTP is up after $ATTEMPT attempts."

  echo "[bundle] ---- Phase 2: Waiting for owner account to be created ----"
  ATTEMPT=0
  until curl -sf "http://$SELF_IP:$N8N_PORT/rest/settings" | grep -q 'isInstanceOwnerSetUp.*true'; do
    ATTEMPT=$((ATTEMPT + 1))
    OWNER_STATUS=$(curl -sf "http://$SELF_IP:$N8N_PORT/rest/settings" 2>/dev/null | grep -o 'isInstanceOwnerSetUp[^,}]*' || echo "unknown")
    echo "[bundle] Owner check attempt $ATTEMPT — current: $OWNER_STATUS — retrying in 5s..."
    sleep 5
  done
  echo "[bundle] Owner account detected after $ATTEMPT attempts."

  echo "[bundle] ---- Phase 3: Importing workflows ----"
  SUCCESS=0
  FAIL=0
  for f in /workflows/*.json; do
    echo "[bundle] Importing: $f"
    if n8n import:workflow --input="$f"; then
      echo "[bundle] OK: $f"
      SUCCESS=$((SUCCESS + 1))
    else
      echo "[bundle] FAILED: $f"
      FAIL=$((FAIL + 1))
    fi
  done

  touch "$IMPORTED_FLAG"
  echo "[bundle] ============================================"
  echo "[bundle] Import complete: $SUCCESS succeeded, $FAIL failed"
  echo "[bundle] Refresh your browser to see the workflows."
  echo "[bundle] ============================================"
fi

echo "[bundle] Handing control to n8n (PID $N8N_PID)..."
wait $N8N_PID
