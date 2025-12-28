#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

python -m venv .venv
source .venv/bin/activate
python -m pip install -U pip setuptools wheel
python -m pip install --no-cache-dir -r requirements.txt

echo "Running Atlas backend on http://127.0.0.1:8000"
python -m uvicorn asgi:app --host 127.0.0.1 --port 8000
