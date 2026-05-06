#!/bin/sh
set -e

export N8N_PORT=${PORT:-5678}
export N8N_USER_FOLDER=${N8N_USER_FOLDER:-/data/n8n}

mkdir -p "$N8N_USER_FOLDER"
chmod -R 777 "$N8N_USER_FOLDER"

IMPORTED_FLAG="$N8N_USER_FOLDER/.workflows-imported"

# Import workflows in background AFTER n8n starts and owner is set up
if [ ! -f "$IMPORTED_FLAG" ]; then
  (
    echo "[bundle] Waiting for n8n to start..."
    # Wait for n8n to be ready
    until curl -sf "http://localhost:$N8N_PORT/healthz" > /dev/null 2>&1; do
      sleep 3
    done
    echo "[bundle] n8n is up. Waiting for owner account to be created..."
    # Wait until the owner account is actually set up
    until curl -sf "http://localhost:$N8N_PORT/rest/settings" | grep -q '"isInstanceOwnerSetUp":\s*true'; do
      sleep 5
    done
    echo "[bundle] Owner account detected. Importing workflows..."
    echo "[bundle] Importing ecom workflow bundle..."
    for f in /workflows/*.json; do
      echo "[bundle] Importing: $f"
      n8n import:workflow --input="$f" && echo "[bundle] OK: $f" || echo "[bundle] Failed: $f"
    done
    touch "$IMPORTED_FLAG"
    echo "[bundle] Done. Refresh your browser to see workflows."
  ) &
fi

echo "Starting n8n on port $N8N_PORT..."
exec n8n start
