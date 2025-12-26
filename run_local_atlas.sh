#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
  python -m venv .venv
fi

source .venv/bin/activate

pip install -q --upgrade pip
[ -f requirements.txt ] && pip install -q -r requirements.txt || pip install -q fastapi uvicorn pydantic python-dotenv

# عدّل المسار إن لزم
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
