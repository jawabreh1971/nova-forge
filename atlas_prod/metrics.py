from __future__ import annotations
from typing import Optional
try:
    from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
except Exception:  # pragma: no cover
    Counter = None
    Histogram = None
    generate_latest = None
    CONTENT_TYPE_LATEST = "text/plain"

_REQUESTS = Counter("atlas_http_requests_total", "HTTP requests", ["method", "path", "status"]) if Counter else None
_LAT = Histogram("atlas_http_request_latency_seconds", "HTTP latency", ["path"]) if Histogram else None

def observe(method: str, path: str, status: int, latency_seconds: float) -> None:
    if _REQUESTS:
        _REQUESTS.labels(method=method, path=path, status=str(status)).inc()
    if _LAT:
        _LAT.labels(path=path).observe(latency_seconds)

def render_metrics() -> tuple[bytes, str]:
    if generate_latest is None:
        return b"# metrics disabled\n", "text/plain"
    return generate_latest(), CONTENT_TYPE_LATEST

