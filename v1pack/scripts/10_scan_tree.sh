#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(pwd)"
echo "[10] Backend-only mode scan..."

# Detect backend
BACK=""
for d in backend server api; do
  if [ -d "$ROOT/$d" ]; then BACK="$ROOT/$d"; break; fi
done
if [ -z "$BACK" ]; then
  cand="$(find "$ROOT" -maxdepth 3 -name requirements.txt -o -name pyproject.toml 2>/dev/null | head -n 1 || true)"
  [ -n "$cand" ] && BACK="$(dirname "$cand")"
fi

echo "FRONT=" | tee "$ROOT/v1pack/out/scan.env"
echo "BACK=$BACK"  | tee -a "$ROOT/v1pack/out/scan.env"

[ -z "$BACK" ]  && echo "[10] ERROR: backend not found" && exit 1
echo "[10] OK BACK=$BACK"
