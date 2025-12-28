from __future__ import annotations
from dataclasses import dataclass
from fastapi import Request
from fastapi.responses import JSONResponse

@dataclass(frozen=True)
class AtlasError(Exception):
    error_code: str
    message: str
    status_code: int = 400

def json_error(request: Request, err: AtlasError, request_id: str | None) -> JSONResponse:
    payload = {
        "ok": False,
        "error_code": err.error_code,
        "message": err.message,
        "request_id": request_id,
        "path": str(request.url.path),
    }
    return JSONResponse(payload, status_code=err.status_code)

