#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ============================================
# Nova Forge — v1pack RUN_ALL (FIXED)
# - Builds frontend (if possible)
# - Copies frontend/dist -> backend/static
# - Installs backend deps in root .venv
# - Runs uvicorn backend.app:app
# ============================================

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[RUN_ALL] Root: $ROOT_DIR"

# ---- sanity
for p in backend backend/app.py frontend frontend/package.json; do
  if [ ! -e "$ROOT_DIR/$p" ]; then
    echo "ERROR: missing: $p"
    exit 1
  fi
done

# ---- ensure python
if ! command -v python >/dev/null 2>&1; then
  echo "ERROR: python not found. Termux: pkg install python"
  exit 1
fi

# ---- ensure node/npm (only if we want to build)
HAS_NODE=1
command -v node >/dev/null 2>&1 || HAS_NODE=0
command -v npm  >/dev/null 2>&1 || HAS_NODE=0

# ---- build frontend if node exists
if [ "$HAS_NODE" -eq 1 ]; then
  echo "[1/6] Build frontend..."
  cd "$ROOT_DIR/frontend"

  if [ -f "package-lock.json" ]; then
    npm ci
  else
    npm install
  fi

  npm run build

  if [ ! -d "dist" ]; then
    echo "ERROR: frontend build failed: dist/ not found"
    exit 1
  fi
else
  echo "[1/6] Skip frontend build (node/npm not found). Will use existing frontend/dist if present."
fi

# ---- copy dist -> backend/static (must exist after build or already present)
echo "[2/6] Sync frontend/dist -> backend/static ..."
cd "$ROOT_DIR"

if [ ! -d "$ROOT_DIR/frontend/dist" ]; then
  echo "ERROR: frontend/dist not found. Either install nodejs and build, or provide dist."
  exit 1
fi

rm -rf "$ROOT_DIR/backend/static"
mkdir -p "$ROOT_DIR/backend/static"
cp -R "$ROOT_DIR/frontend/dist/"* "$ROOT_DIR/backend/static/" || true

# ---- venv (use root .venv if exists, else create)
echo "[3/6] Setup venv + backend deps..."
cd "$ROOT_DIR"

if [ ! -d "$ROOT_DIR/.venv" ]; then
  python -m venv "$ROOT_DIR/.venv"
fi

# shellcheck disable=SC1091
. "$ROOT_DIR/.venv/bin/activate"

python -m pip install --upgrade pip >/dev/null 2>&1 || true

# install backend requirements
pip install -r "$ROOT_DIR/backend/requirements.txt"

# ---- env defaults
echo "[4/6] Export env defaults..."
export ATLAS_ENV="${ATLAS_ENV:-dev}"
export ATLAS_VERSION="${ATLAS_VERSION:-v1pack-ai-win-1.0.0}"
export ATLAS_MODEL="${ATLAS_MODEL:-gpt-4o-mini}"
export ATLAS_MEDIA_DIR="${ATLAS_MEDIA_DIR:-$ROOT_DIR/data/media}"
mkdir -p "$ATLAS_MEDIA_DIR" >/dev/null 2>&1 || true

# ---- run
echo "[5/6] Run uvicorn (Backend serves /api and / from backend/static)..."
echo "URL:    http://127.0.0.1:8000"
echo "Health: http://127.0.0.1:8000/api/health"
echo ""

exec uvicorn backend.app:app --host 0.0.0.0 --port 8000
