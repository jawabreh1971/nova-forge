#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:8080}"
echo "[SMOKE] GET $BASE/health"
curl -fsS "$BASE/health" | head
echo ""
echo "[SMOKE] GET $BASE/ready"
curl -fsS "$BASE/ready" | head
echo ""
echo "[SMOKE] GET $BASE/metrics"
curl -fsS "$BASE/metrics" | head
echo ""
echo "[SMOKE] OK"
