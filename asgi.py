import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import PlainTextResponse
from fastapi import FastAPI, HTTPException
from typing import Any, Dict, List, Optional

app = FastAPI(title="Nova-Forge (Atlas)")
import atlas_runtime

@app.get("/healthz")
def healthz():
    return {"status": "ok"}
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class ChatIn(BaseModel):
    message: str
    session_id: Optional[str] = "default"
    meta: Optional[Dict[str, Any]] = None

class ChatOut(BaseModel):
    reply: str
    session_id: str

@app.post("/api/chat", response_model=ChatOut)
def api_chat(payload: ChatIn):
    msg = (payload.message or "").strip()
    if not msg:
        return {"reply": "اكتب رسالة أولاً.", "session_id": payload.session_id or "default"}
    # MVP reply (Echo) — جاهز للربط مع LLM لاحقًا
    return {"reply": f"Atlas Echo: {msg}", "session_id": payload.session_id or "default"}


BASE_DIR = os.path.dirname(__file__)
FRONTEND_DIST = os.path.join(BASE_DIR, "frontend", "dist")
INDEX_HTML = os.path.join(FRONTEND_DIST, "index.html")

# Serve React build at root
if os.path.isfile(INDEX_HTML):
    app.mount("/", StaticFiles(directory=FRONTEND_DIST, html=True), name="frontend")
else:
    @app.get("/")
    def root_backend_only():
        return PlainTextResponse(
            f"OK (backend). UI missing at: {INDEX_HTML}",
            status_code=200
        )

# === ATLAS API (Settings + Chat) ===

@app.get("/api/settings")
def api_get_settings() -> Dict[str, Any]:
    settings = atlas_runtime.load_settings()
    return atlas_runtime.masked_settings(settings)

@app.post("/api/settings")
def api_set_settings(payload: Dict[str, Any]) -> Dict[str, Any]:
    # Minimal protection: optional ADMIN_TOKEN
    admin_token = (os.getenv("ATLAS_ADMIN_TOKEN", "") or "").strip()
    if admin_token:
        supplied = (payload.get("admin_token") or "").strip()
        if supplied != admin_token:
            raise HTTPException(status_code=401, detail="Unauthorized")

    patch = dict(payload)
    patch.pop("admin_token", None)
    settings = atlas_runtime.save_settings(patch)
    return atlas_runtime.masked_settings(settings)

@app.post("/api/chat")
async def api_chat(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    payload:
      - messages: [{role: 'system'|'user'|'assistant', content: '...'}]
    """
    messages = payload.get("messages", [])
    if not isinstance(messages, list) or not messages:
        raise HTTPException(status_code=400, detail="messages[] required")

    settings = atlas_runtime.load_settings()
    try:
        text = await atlas_runtime.openai_chat(messages=messages, settings=settings)
        return {"ok": True, "reply": text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)[:500])
