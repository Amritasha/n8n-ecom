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

# Railway's container network blocks all in-container access to n8n's port —
# loopback, [::1], and even eth0 IP all give conn_refused. n8n is only
# reachable via Railway's external proxy. So we bounce through the public URL.
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  N8N_URL="https://$RAILWAY_PUBLIC_DOMAIN"
elif [ -n "$RAILWAY_STATIC_URL" ]; then
  N8N_URL="https://$RAILWAY_STATIC_URL"
else
  # Last-ditch fallback: try eth0 IP (works outside Railway)
  SELF_IP=$(ip -4 addr show scope global 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
  [ -z "$SELF_IP" ] && SELF_IP="127.0.0.1"
  N8N_URL="http://$SELF_IP:$N8N_PORT"
fi
echo "[bundle] Health-check URL: $N8N_URL"

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
  until curl -sf "$N8N_URL/healthz" > /dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$N8N_URL/healthz" 2>/dev/null || echo "conn_refused")
    echo "[bundle] Health check attempt $ATTEMPT — $N8N_URL/healthz — HTTP $HTTP_CODE — retrying in 3s..."
    sleep 3
  done
  echo "[bundle] n8n HTTP is up after $ATTEMPT attempts."

  echo "[bundle] ---- Phase 2: Waiting for owner account to be created ----"
  ATTEMPT=0
  until curl -sf "$N8N_URL/rest/settings" | grep -q 'isInstanceOwnerSetUp.*true'; do
    ATTEMPT=$((ATTEMPT + 1))
    OWNER_STATUS=$(curl -sf "$N8N_URL/rest/settings" 2>/dev/null | grep -o 'isInstanceOwnerSetUp[^,}]*' || echo "unknown")
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
