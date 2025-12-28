#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "[AtlasProdPack] Applying overlay files... (non-destructive)"
# This pack is expected to already be unzipped into repo root.
# Ensure permissions
chmod +x ops/termux/*.sh || true

# Add Dockerfile if missing; keep existing if present.
if [ ! -f Dockerfile ]; then
  echo "[AtlasProdPack] No Dockerfile found, installing Dockerfile.atlas_prod as Dockerfile"
  cp -f Dockerfile.atlas_prod Dockerfile
else
  echo "[AtlasProdPack] Dockerfile exists. Keeping it. A reference Dockerfile is available as Dockerfile.atlas_prod"
fi

# .dockerignore overlay (append-safe)
if [ ! -f .dockerignore ]; then
  cp -f .dockerignore.atlas_prod .dockerignore
else
  echo "[AtlasProdPack] .dockerignore exists. Not overwriting. Reference at .dockerignore.atlas_prod"
fi

echo ""
echo "[AtlasProdPack] Next manual step (ONE LINE):"
echo "1) Open your FastAPI app creation file (e.g. backend/app/main.py)"
echo "2) After: app = FastAPI(...)  add:"
echo "   from atlas_prod.bootstrap import apply_production_defaults"
echo "   apply_production_defaults(app)"
echo ""
echo "[AtlasProdPack] Requirements:"
echo "Merge requirements-prod.txt into your requirements file if needed."
echo ""
echo "Run local:"
echo "bash ops/termux/run_local_prod.sh"
