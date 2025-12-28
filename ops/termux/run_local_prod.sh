#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Adjust these if your backend lives elsewhere:
BACKEND_DIR="${BACKEND_DIR:-backend}"
APP_IMPORT="${APP_IMPORT:-app.main:app}"   # example: app.main:app or main:app

cd "$BACKEND_DIR"

python -m venv .venv 2>/dev/null || true
source .venv/bin/activate

python -m pip install -U pip wheel setuptools
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi
if [ -f ../requirements-prod.txt ]; then
  pip install -r ../requirements-prod.txt
fi

export ATLAS_ENV="${ATLAS_ENV:-dev}"
export ATLAS_LOG_LEVEL="${ATLAS_LOG_LEVEL:-INFO}"
export ATLAS_ENABLE_METRICS="${ATLAS_ENABLE_METRICS:-1}"
export ATLAS_ENABLE_RATE_LIMIT="${ATLAS_ENABLE_RATE_LIMIT:-0}"

python -m uvicorn "$APP_IMPORT" --host 0.0.0.0 --port 8080 --reload
