#!/bin/sh
set -e

WORKFLOWS_DIR="/workflows"
IMPORTED_FLAG="/home/node/.n8n/.workflows-imported"

if [ ! -f "$IMPORTED_FLAG" ]; then
  echo "Importing ecom workflow bundle..."
  for f in "$WORKFLOWS_DIR"/*.json; do
    echo "Importing: $f"
    n8n import:workflow --input="$f" || echo "Warning: failed to import $f"
  done
  touch "$IMPORTED_FLAG"
  echo "Workflow import complete."
fi

exec n8n start
