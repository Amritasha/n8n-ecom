#!/bin/sh
set -e

export N8N_PORT=${PORT:-5678}
export N8N_USER_FOLDER=${N8N_USER_FOLDER:-/data/n8n}

mkdir -p "$N8N_USER_FOLDER"
chmod -R 777 "$N8N_USER_FOLDER"

IMPORTED_FLAG="$N8N_USER_FOLDER/.workflows-imported"

echo "Starting n8n on port $N8N_PORT..."
n8n start &
N8N_PID=$!

# Forward SIGTERM/SIGINT to n8n
trap "kill $N8N_PID; exit" TERM INT

if [ ! -f "$IMPORTED_FLAG" ]; then
  echo "[bundle] Waiting for n8n to start..."
  until curl -sf "http://localhost:$N8N_PORT/healthz" > /dev/null 2>&1; do
    sleep 3
  done

  echo "[bundle] n8n is up. Waiting for owner account to be created..."
  until curl -sf "http://localhost:$N8N_PORT/rest/settings" | grep -q 'isInstanceOwnerSetUp.*true'; do
    sleep 5
  done

  echo "[bundle] Owner account detected. Importing workflows..."
  for f in /workflows/*.json; do
    echo "[bundle] Importing: $f"
    n8n import:workflow --input="$f" && echo "[bundle] OK: $f" || echo "[bundle] Failed: $f"
  done
  touch "$IMPORTED_FLAG"
  echo "[bundle] Done. Refresh your browser to see workflows."
fi

wait $N8N_PID
