import os
from fastapi import FastAPI

app = FastAPI(title="Nova-Forge (Atlas)")

@app.get("/")
def root():
    return {"service": "nova-forge", "status": "ok"}

@app.get("/healthz")
def healthz():
    return {"ok": True, "port": os.getenv("PORT")}
