from __future__ import annotations
import time
import uuid
import logging
from typing import Callable, Optional, Dict, Tuple
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

logger = logging.getLogger("atlas")

class CorrelationIdMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp, header_name: str = "x-request-id") -> None:
        super().__init__(app)
        self.header_name = header_name

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        rid = request.headers.get(self.header_name) or str(uuid.uuid4())
        request.state.request_id = rid
        start = time.time()
        resp = await call_next(request)
        dur_ms = int((time.time() - start) * 1000)
        resp.headers[self.header_name] = rid
        # log access line
        rec = logging.LogRecord(
            name="atlas.access",
            level=logging.INFO,
            pathname=__file__,
            lineno=0,
            msg="request",
            args=(),
            exc_info=None,
        )
        rec.request_id = rid
        rec.method = request.method
        rec.path = request.url.path
        rec.status_code = resp.status_code
        rec.duration_ms = dur_ms
        logging.getLogger("atlas.access").handle(rec)
        return resp

class SimpleRateLimiter(BaseHTTPMiddleware):
    """Basic in-memory token bucket per IP.
    NOTE: On multi-instance deployments, this is per-instance. Good as a guard, not a billing system.
    """
    def __init__(self, app: ASGIApp, rps: int = 5, burst: int = 10) -> None:
        super().__init__(app)
        self.rps = max(1, int(rps))
        self.burst = max(self.rps, int(burst))
        self.state: Dict[str, Tuple[float, float]] = {}  # ip -> (tokens, last_ts)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        ip = request.client.host if request.client else "unknown"
        now = time.time()
        tokens, last = self.state.get(ip, (float(self.burst), now))
        # refill
        elapsed = max(0.0, now - last)
        tokens = min(float(self.burst), tokens + elapsed * float(self.rps))
        if tokens < 1.0:
            return Response(content="rate_limited", status_code=429)
        tokens -= 1.0
        self.state[ip] = (tokens, now)
        return await call_next(request)

