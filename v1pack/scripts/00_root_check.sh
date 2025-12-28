#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(pwd)"
echo "[00] ROOT = $ROOT"
test -d .git || echo "[00] WARN: .git not found (ok if not initialized yet)."
# Ensure expected folders exist or will be detected later
ls -la | head -n 30 || true
