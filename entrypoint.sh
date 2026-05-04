#!/bin/sh
set -e

# Fix volume permissions
mkdir -p /home/node/.n8n
chmod -R 777 /home/node/.n8n

# Import workflows in background after n8n starts
(
  sleep 30
  IMPORTED_FLAG="/home/node/.n8n/.workflows-imported"
  if [ ! -f "$IMPORTED_FLAG" ]; then
    echo "[bundle] Importing ecom workflow bundle..."
    for f in /workflows/*.json; do
      echo "[bundle] Importing: $f"
      n8n import:workflow --input="$f" || echo "[bundle] Warning: failed to import $f"
    done
    touch "$IMPORTED_FLAG"
    echo "[bundle] Workflow import complete."
  fi
) &

echo "Starting n8n on port ${N8N_PORT}..."
exec n8n start
