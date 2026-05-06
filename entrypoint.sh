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

if [ -f "$IMPORTED_FLAG" ]; then
  echo "[bundle] Flag exists — workflows already imported. Skipping."
else
  echo "[bundle] ---- Importing workflows directly into SQLite (before n8n server starts) ----"
  echo "[bundle] The import CLI writes to the DB directly — no HTTP needed."

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

  if [ $SUCCESS -gt 0 ]; then
    touch "$IMPORTED_FLAG"
    echo "[bundle] ============================================"
    echo "[bundle] Import complete: $SUCCESS succeeded, $FAIL failed"
    echo "[bundle] Workflows are in the DB. After you finish owner setup,"
    echo "[bundle] refresh your browser to see them."
    echo "[bundle] ============================================"
  else
    echo "[bundle] All imports failed — flag NOT set, will retry next deploy."
  fi
fi

echo "[bundle] Handing control to n8n on port $N8N_PORT..."
exec n8n start
