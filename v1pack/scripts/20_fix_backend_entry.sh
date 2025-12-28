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
