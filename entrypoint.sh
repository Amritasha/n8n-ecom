#!/bin/sh
set -e

# Bind n8n to Railway's dynamic PORT
export N8N_PORT=${PORT:-5678}
export N8N_USER_FOLDER=${N8N_USER_FOLDER:-/data/n8n}

# Fix permissions on data folder
mkdir -p "$N8N_USER_FOLDER"
chmod -R 777 "$N8N_USER_FOLDER"

# Import workflows once before starting n8n
IMPORTED_FLAG="$N8N_USER_FOLDER/.workflows-imported"
echo "[bundle] Data folder: $N8N_USER_FOLDER"
echo "[bundle] Flag file: $IMPORTED_FLAG"
echo "[bundle] Flag exists: $([ -f "$IMPORTED_FLAG" ] && echo yes || echo no)"
if [ ! -f "$IMPORTED_FLAG" ]; then
  echo "[bundle] Importing ecom workflow bundle..."
  for f in /workflows/*.json; do
    echo "[bundle] Importing: $f"
    n8n import:workflow --input="$f" && echo "[bundle] OK" || echo "[bundle] Warning: failed to import $f"
  done
  touch "$IMPORTED_FLAG"
  echo "[bundle] Workflow import complete."
else
  echo "[bundle] Workflows already imported, skipping."
fi

echo "Starting n8n on port $N8N_PORT..."
exec n8n start
