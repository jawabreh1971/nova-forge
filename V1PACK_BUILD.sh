#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(pwd)"
PACK="$ROOT/v1pack"
mkdir -p "$PACK/scripts" "$PACK/out"

cat > "$PACK/README.txt" <<'TXT'
V1 PACK (Termux + Render) - Nova/Atlas
- RUN: bash v1pack/RUN_ALL.sh
- Individual scripts are in v1pack/scripts/
- Produces:
  - Local smoke tests
  - Frontend build served by FastAPI (single service)
  - render.yaml for Render native deploy
  - Atlas Grade report
TXT

cat > "$PACK/RUN_ALL.sh" <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
bash "$HERE/scripts/00_root_check.sh"
bash "$HERE/scripts/10_scan_tree.sh"
bash "$HERE/scripts/20_fix_backend_entry.sh"
bash "$HERE/scripts/30_link_frontend_single_service.sh"
bash "$HERE/scripts/40_build_frontend.sh"
bash "$HERE/scripts/50_smoke_local.sh"
bash "$HERE/scripts/60_render_yaml.sh"
bash "$HERE/scripts/70_atlas_grade.sh"
echo "DONE. Next: git add/commit/push, then connect repo in Render."
SH
chmod +x "$PACK/RUN_ALL.sh"

cat > "$PACK/scripts/00_root_check.sh" <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(pwd)"
echo "[00] ROOT = $ROOT"
test -d .git || echo "[00] WARN: .git not found (ok if not initialized yet)."
# Ensure expected folders exist or will be detected later
ls -la | head -n 30 || true
SH
chmod +x "$PACK/scripts/00_root_check.sh"

cat > "$PACK/scripts/10_scan_tree.sh" <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
echo "[10] scanning for backend/frontend..."
ROOT="$(pwd)"

# Detect frontend
FRONT=""
for d in frontend client web ui; do
  if [ -d "$ROOT/$d" ] && [ -f "$ROOT/$d/package.json" ]; then FRONT="$ROOT/$d"; break; fi
done
if [ -z "$FRONT" ]; then
  # fallback: search package.json candidates
  cand="$(find "$ROOT" -maxdepth 3 -name package.json 2>/dev/null | head -n 1 || true)"
  if [ -n "$cand" ]; then FRONT="$(dirname "$cand")"; fi
fi

# Detect backend
BACK=""
for d in backend server api; do
  if [ -d "$ROOT/$d" ]; then BACK="$ROOT/$d"; break; fi
done
if [ -z "$BACK" ]; then
  # fallback: look for requirements/pyproject
  cand="$(find "$ROOT" -maxdepth 3 -name requirements.txt -o -name pyproject.toml 2>/dev/null | head -n 1 || true)"
  if [ -n "$cand" ]; then BACK="$(dirname "$cand")"; fi
fi

echo "FRONT=$FRONT" | tee "$ROOT/v1pack/out/scan.env"
echo "BACK=$BACK"  | tee -a "$ROOT/v1pack/out/scan.env"

if [ -z "$FRONT" ]; then echo "[10] ERROR: frontend not found"; exit 1; fi
if [ -z "$BACK"  ]; then echo "[10] ERROR: backend not found"; exit 1; fi

echo "[10] OK: FRONT=$FRONT"
echo "[10] OK: BACK=$BACK"
SH
chmod +x "$PACK/scripts/10_scan_tree.sh"

cat > "$PACK/scripts/20_fix_backend_entry.sh" <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(pwd)"
source "$ROOT/v1pack/out/scan.env"
echo "[20] fixing backend entry in: $BACK"

mkdir -p "$BACK"

# Create stable FastAPI entry
cat > "$BACK/app.py" <<'PY'
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from pathlib import Path

app = FastAPI(title="Nova Forge", version="1.0.0")

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

# Static mount (built frontend will be copied to backend/static)
STATIC_DIR = Path(__file__).parent / "static"
if STATIC_DIR.exists():
    app.mount("/", StaticFiles(directory=str(STATIC_DIR), html=True), name="static")
PY

# Termux-safe requirements (pin stable)
cat > "$BACK/requirements.txt" <<'REQ'
fastapi==0.110.0
uvicorn==0.29.0
pydantic==2.6.4
REQ

# Start script
cat > "$BACK/start.sh" <<'BASH'
#!/usr/bin/env bash
set -e
PORT="${PORT:-8000}"
exec python -m uvicorn app:app --host 0.0.0.0 --port "$PORT"
