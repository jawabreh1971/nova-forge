from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime

app = FastAPI(title="Nova Forge (Backend Only)", version="1.0.0")

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/info")
def info():
    return {
        "name": "nova-forge-backend-only",
        "version": "1.0.0",
        "ts": datetime.utcnow().isoformat() + "Z",
    }

class ChatIn(BaseModel):
    message: str

@app.post("/chat")
def chat(payload: ChatIn):
    # Stub (later we connect real LLM gateway)
    return {"reply": f"Echo: {payload.message}"}
