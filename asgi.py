import os
from fastapi import FastAPI

app = FastAPI(title="Nova-Forge (Atlas)")

@app.get("/")
def root():
    return {"service": "nova-forge", "status": "ok"}

@app.get("/healthz")
def healthz():
    return {"ok": True, "port": os.getenv("PORT")}


@app.get("/health")
def health():
    return {"status": "ok"}

from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path
import json

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

SETTINGS_FILE = Path(__file__).parent / "settings_store.json"

def _load_settings():
    if SETTINGS_FILE.exists():
        try:
            return json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}

def _save_settings(payload: dict):
    SETTINGS_FILE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return True

@app.get("/api/settings")
def api_get_settings():
    return _load_settings()

@app.post("/api/settings")
def api_save_settings(payload: dict):
    _save_settings(payload)
    return {"ok": True, "saved_keys": sorted(list(payload.keys()))}

FRONTEND_DIST = Path(__file__).parent / "frontend" / "dist"
FRONTEND_INDEX = FRONTEND_DIST / "index.html"

if FRONTEND_DIST.exists():
    app.mount("/", StaticFiles(directory=str(FRONTEND_DIST), html=True), name="frontend")

    @app.get("/")
    def frontend_index():
        if FRONTEND_INDEX.exists():
            return FileResponse(str(FRONTEND_INDEX))
        return {"status": "frontend_missing_index"}
