from __future__ import annotations
import time
import os
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse, Response
from .settings import load_settings
from .metrics import render_metrics

router = APIRouter()

@router.get("/health")
def health() -> dict:
    s = load_settings()
    return {"ok": True, "service": s.service_name, "env": s.env, "ts": int(time.time())}

@router.get("/ready")
def ready() -> dict:
    # Hook point: if you have DB/external deps, implement checks here.
    return {"ok": True}

@router.get("/metrics")
def metrics() -> Response:
    body, ctype = render_metrics()
    return Response(content=body, media_type=ctype)

