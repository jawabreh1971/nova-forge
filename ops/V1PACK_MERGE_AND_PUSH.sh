#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$HOME/nova-forge"
cd "$ROOT"

echo "[A] Repo root: $ROOT"

# 1) Build Frontend (Vite)
echo "[B] Build frontend..."
cd "$ROOT/frontend"
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi
npm run build

if [ ! -d "$ROOT/frontend/dist" ]; then
  echo "ERROR: frontend/dist not found after build"
  exit 1
fi

# 2) Sync dist -> backend/static
echo "[C] Sync frontend/dist -> backend/static ..."
cd "$ROOT"
rm -rf "$ROOT/backend/static"
mkdir -p "$ROOT/backend/static"
cp -R "$ROOT/frontend/dist/"* "$ROOT/backend/static/" || true

# 3) Optional: syntax compile (no imports, safe)
echo "[D] Python syntax check (compile only, no deps)..."
python -m compileall -q "$ROOT/backend" || true

# 4) Git commit + push
echo "[E] Git status:"
git status -sb || true

echo "[F] Commit changes..."
git add -A
git commit -m "v1pack: windows-like UI + media panels + static served by backend" || echo "No changes to commit."

echo "[G] Push to GitHub..."
git push

echo "DONE: merged v1pack frontend into backend/static and pushed."
