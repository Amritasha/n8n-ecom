#!/bin/sh
set -e

# Bind n8n to Railway's dynamic PORT
export N8N_PORT=${PORT:-5678}

WORKFLOWS_DIR="/workflows"
IMPORTED_FLAG="/home/node/.n8n/.workflows-imported"

# Run workflow import in background AFTER n8n starts (so healthcheck passes quickly)
(
  sleep 30
  if [ ! -f "$IMPORTED_FLAG" ]; then
    echo "[bundle] Importing ecom workflow bundle..."
    for f in "$WORKFLOWS_DIR"/*.json; do
      echo "[bundle] Importing: $f"
      n8n import:workflow --input="$f" || echo "[bundle] Warning: failed to import $f"
    done
    mkdir -p /home/node/.n8n
    touch "$IMPORTED_FLAG"
    echo "[bundle] Workflow import complete."
  fi
) &

echo "Starting n8n on port $N8N_PORT..."
exec n8n start
