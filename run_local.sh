#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/nova-forge"

python -m venv .venv 2>/dev/null || true
source .venv/bin/activate

pip install -U pip setuptools wheel
pip install -r requirements.txt

export PYTHONPATH="$PWD"
exec python -m uvicorn nova.app:app --host 0.0.0.0 --port 8000
