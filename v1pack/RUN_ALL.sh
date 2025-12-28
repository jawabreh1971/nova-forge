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
bash "$HERE/scripts/80_zip_backend_only.sh"

echo "DONE. Backend-only pack zipped."
