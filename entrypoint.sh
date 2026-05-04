#!/bin/sh
set -e

export N8N_PORT=${PORT:-5678}
export N8N_BASIC_AUTH_ACTIVE=true

# Fix volume permissions — Railway mounts volumes as root
mkdir -p /home/node/.n8n
chown -R node:node /home/node/.n8n

# Import workflows in background after n8n starts
(
  sleep 30
  IMPORTED_FLAG="/home/node/.n8n/.workflows-imported"
  if [ ! -f "$IMPORTED_FLAG" ]; then
    echo "[bundle] Importing ecom workflow bundle..."
    for f in /workflows/*.json; do
      echo "[bundle] Importing: $f"
      gosu node n8n import:workflow --input="$f" || echo "[bundle] Warning: failed to import $f"
    done
    touch "$IMPORTED_FLAG"
    echo "[bundle] Workflow import complete."
  fi
) &

echo "Starting n8n on port $N8N_PORT..."
exec gosu node n8n start
