from __future__ import annotations
from dataclasses import dataclass
import os

def _get(name: str, default: str | None = None) -> str | None:
    v = os.getenv(name)
    return v if v is not None and v != "" else default

def _get_int(name: str, default: int) -> int:
    v = _get(name)
    if v is None:
        return default
    try:
        return int(v)
    except Exception:
        return default

def _get_bool(name: str, default: bool) -> bool:
    v = _get(name)
    if v is None:
        return default
    return v.strip().lower() in ("1", "true", "yes", "on")

@dataclass(frozen=True)
class ProdSettings:
    env: str = "dev"
    service_name: str = "atlas"
    version: str = "0.0.0"
    log_level: str = "INFO"
    enable_metrics: bool = True
    metrics_path: str = "/metrics"

    enable_rate_limit: bool = False
    rate_limit_rps: int = 5
    rate_limit_burst: int = 10

    enable_audit: bool = False
    audit_path: str = "./data/audit.log"

def load_settings() -> ProdSettings:
    env = _get("ATLAS_ENV", "dev")
    s = ProdSettings(
        env=env,
        service_name=_get("ATLAS_SERVICE_NAME", "atlas") or "atlas",
        version=_get("ATLAS_VERSION", "0.0.0") or "0.0.0",
        log_level=_get("ATLAS_LOG_LEVEL", "INFO") or "INFO",
        enable_metrics=_get_bool("ATLAS_ENABLE_METRICS", True),
        metrics_path=_get("ATLAS_METRICS_PATH", "/metrics") or "/metrics",
        enable_rate_limit=_get_bool("ATLAS_ENABLE_RATE_LIMIT", False),
        rate_limit_rps=_get_int("ATLAS_RATE_LIMIT_RPS", 5),
        rate_limit_burst=_get_int("ATLAS_RATE_LIMIT_BURST", 10),
        enable_audit=_get_bool("ATLAS_ENABLE_AUDIT", False),
        audit_path=_get("ATLAS_AUDIT_PATH", "./data/audit.log") or "./data/audit.log",
    )
    return s

