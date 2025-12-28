#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/nova-forge"

# build v1pack if missing
if [ ! -d v1pack ]; then
  echo "[BUILD] creating v1pack..."
  # (يبني V1PACK_BUILD + يشغل RUN_ALL) من الإصدار الذي أعطيتك إياه سابقًا
  # لو كان V1PACK_BUILD.sh موجود شغّله، وإلا اطبع رسالة واضحة
  if [ -f V1PACK_BUILD.sh ]; then
    bash V1PACK_BUILD.sh
  else
    echo "ERROR: V1PACK_BUILD.sh not found in repo root."
    echo "Tell me and I will generate it again in a shorter safe paste."
    exit 1
  fi
  bash v1pack/RUN_ALL.sh
fi

# zip
pkg install -y zip >/dev/null 2>&1 || true
TS="$(date +%Y%m%d_%H%M%S)"
mkdir -p deliveries
TMP="deliveries/_stage_v1pack"
rm -rf "$TMP"; mkdir -p "$TMP"
cp -R v1pack "$TMP/v1pack"
[ -f render.yaml ] && cp render.yaml "$TMP/render.yaml" || true
cat > "$TMP/START.txt" <<'TXT'
Nova V1 Pack
1) Unzip
2) cd to repo root (where v1pack exists)
3) bash v1pack/RUN_ALL.sh
TXT
cd "$TMP"
zip -r "../nova_v1pack_${TS}.zip" . >/dev/null
cd "$HOME/nova-forge"
rm -rf "$TMP"
echo "[DONE] $(ls -1t deliveries/nova_v1pack_*.zip | head -n 1)"
