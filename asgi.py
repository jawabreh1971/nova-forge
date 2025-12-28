from __future__ import annotations

import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles

APP_TITLE = "Atlas (Nova-Forge)"
app = FastAPI(title=APP_TITLE, version="1.0.0")


@app.get("/healthz")
def healthz():
    return {"ok": True, "service": "atlas-backend", "version": "1.0.0"}


# ---- Serve frontend build (Vite dist) ----
BASE_DIR = Path(__file__).resolve().parent
DIST_DIR = BASE_DIR / "frontend" / "dist"

if DIST_DIR.exists():
    app.mount("/assets", StaticFiles(directory=str(DIST_DIR / "assets")), name="assets")

    @app.get("/")
    def index():
        index_file = DIST_DIR / "index.html"
        if index_file.exists():
            return FileResponse(str(index_file))
        return JSONResponse({"ok": True, "note": "frontend dist missing index.html"})

    # SPA fallback
    @app.get("/{path:path}")
    def spa_fallback(path: str):
        # if a real file exists inside dist, serve it
        candidate = DIST_DIR / path
        if candidate.exists() and candidate.is_file():
            return FileResponse(str(candidate))

        index_file = DIST_DIR / "index.html"
        if index_file.exists():
            return FileResponse(str(index_file))
        return JSONResponse({"ok": True, "note": "frontend dist not found"})
else:
    @app.get("/")
    def root_no_frontend():
        return {"ok": True, "note": "frontend/dist not present. Build frontend then redeploy."}
