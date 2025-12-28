#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/deliveries"
TS="$(date +%Y%m%d_%H%M%S)"
ZIP="$OUT/nova_v1pack_backend_only_${TS}.zip"
STAGE="$OUT/_stage_backend_only"

mkdir -p "$OUT"

# ensure zip installed
if ! command -v zip >/dev/null 2>&1; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y zip >/dev/null 2>&1
fi

# read BACK from scan.env (required)
if [ ! -f "$ROOT/v1pack/out/scan.env" ]; then
  echo "ERROR: missing v1pack/out/scan.env"
  exit 1
fi
# shellcheck disable=SC1090
source "$ROOT/v1pack/out/scan.env"

if [ -z "${BACK:-}" ] || [ ! -d "$BACK" ]; then
  echo "ERROR: BACK is not set or not a directory: BACK=${BACK:-}"
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"

# package v1pack + backend + render.yaml (if exists)
cp -R "$ROOT/v1pack" "$STAGE/v1pack"
cp -R "$BACK" "$STAGE/backend"

if [ -f "$ROOT/render.yaml" ]; then
  cp "$ROOT/render.yaml" "$STAGE/render.yaml"
fi

cat > "$STAGE/START.txt" <<'TXT'
Nova V1 Pack (Backend Only)
1) Unzip
2) cd into folder
3) pip install -r backend/requirements.txt
4) cd backend && bash start.sh
Health: GET /healthz
TXT

cd "$STAGE"
zip -r "$ZIP" . >/dev/null
cd "$ROOT"
rm -rf "$STAGE"

echo "[80] OK ZIP created:"
ls -lh "$ZIP"
