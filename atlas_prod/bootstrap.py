from __future__ import annotations
import logging
import time
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from .settings import load_settings
from .logging import configure_logging
from .middleware import CorrelationIdMiddleware, SimpleRateLimiter
from .routes import router as prod_router
from .errors import AtlasError, json_error
from .audit import append_audit
from .metrics import observe

log = logging.getLogger("atlas")

def apply_production_defaults(app: FastAPI) -> None:
    s = load_settings()
    configure_logging(s.log_level)

    # Middlewares
    app.add_middleware(CorrelationIdMiddleware)
    if s.enable_rate_limit:
        app.add_middleware(SimpleRateLimiter, rps=s.rate_limit_rps, burst=s.rate_limit_burst)

    # Routes (health/ready/metrics)
    app.include_router(prod_router)

    # Exception handler (AtlasError)
    @app.exception_handler(AtlasError)
    async def _atlas_error_handler(request: Request, exc: AtlasError):
        rid = getattr(request.state, "request_id", None)
        rec = logging.LogRecord(
            name="atlas.error",
            level=logging.WARNING if exc.status_code < 500 else logging.ERROR,
            pathname=__file__,
            lineno=0,
            msg=exc.message,
            args=(),
            exc_info=None,
        )
        rec.request_id = rid
        rec.error_code = exc.error_code
        logging.getLogger("atlas.error").handle(rec)
        return json_error(request, exc, rid)

    # Catch-all handler
    @app.middleware("http")
    async def _metrics_and_audit(request: Request, call_next):
        start = time.time()
        try:
            resp = await call_next(request)
            return resp
        except Exception as e:
            rid = getattr(request.state, "request_id", None)
            log.exception("Unhandled exception", extra={"request_id": rid})
            return JSONResponse(
                {"ok": False, "error_code": "ATLAS-5001", "message": "INTERNAL_ERROR", "request_id": rid},
                status_code=500,
            )
        finally:
            dur = time.time() - start
            try:
                observe(request.method, request.url.path, getattr(locals().get("resp", None), "status_code", 0), dur)
            except Exception:
                pass
            if s.enable_audit:
                rid = getattr(request.state, "request_id", None)
                try:
                    append_audit(s.audit_path, {"request_id": rid, "method": request.method, "path": request.url.path})
                except Exception:
                    pass

