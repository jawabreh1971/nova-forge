#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/nova-forge"
echo "[ROOT] $(pwd)"

# Ensure zip installed
if ! command -v zip >/dev/null 2>&1; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y zip >/dev/null 2>&1
fi

# If v1pack missing, build it (requires V1PACK_BUILD.sh)
if [ ! -d "v1pack" ]; then
  echo "[BUILD] v1pack not found."
  if [ ! -f "V1PACK_BUILD.sh" ]; then
    echo "ERROR: V1PACK_BUILD.sh not found in repo root."
    echo "Tell me: 'اعطيني V1PACK_BUILD.sh' وسأعيد توليده بشكل آمن."
    exit 1
  fi
  bash V1PACK_BUILD.sh
fi

# Run pack pipeline if present
if [ -f "v1pack/RUN_ALL.sh" ]; then
  bash v1pack/RUN_ALL.sh
else
  echo "ERROR: v1pack/RUN_ALL.sh missing."
  exit 1
fi

# Create ZIP
TS="$(date +%Y%m%d_%H%M%S)"
mkdir -p deliveries
TMP="deliveries/_stage_v1pack"
rm -rf "$TMP"
mkdir -p "$TMP"

cp -R v1pack "$TMP/v1pack"
[ -f render.yaml ] && cp render.yaml "$TMP/render.yaml" || true

cat > "$TMP/START.txt" <<'TXT'
Nova V1 Pack
1) Unzip
2) cd to repo root (where v1pack/ exists)
3) bash v1pack/RUN_ALL.sh
TXT

cd "$TMP"
ZIP_PATH="../nova_v1pack_${TS}.zip"
zip -r "$ZIP_PATH" . >/dev/null
cd "$HOME/nova-forge"
rm -rf "$TMP"

echo "[DONE] Latest ZIP:"
ls -1t deliveries/nova_v1pack_*.zip | head -n 1
