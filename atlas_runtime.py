import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx

DATA_DIR = Path(os.getenv("ATLAS_DATA_DIR", Path(__file__).parent / "data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)
SETTINGS_PATH = DATA_DIR / "settings.json"

DEFAULTS = {
    "provider": "openai",
    "openai_api_key": "",
    "openai_base_url": "https://api.openai.com/v1",
    "openai_model": "gpt-4o-mini",
}

def _safe_read_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}

def load_settings() -> Dict[str, Any]:
    env_overlay = {
        "provider": os.getenv("ATLAS_PROVIDER", ""),
        "openai_api_key": os.getenv("OPENAI_API_KEY", ""),
        "openai_base_url": os.getenv("OPENAI_BASE_URL", ""),
        "openai_model": os.getenv("OPENAI_MODEL", ""),
    }
    file_data = _safe_read_json(SETTINGS_PATH)
    merged = {**DEFAULTS, **file_data}
    for k, v in env_overlay.items():
        if v:
            merged[k] = v
    return merged

def save_settings(patch: Dict[str, Any]) -> Dict[str, Any]:
    current = load_settings()
    # Only allow known keys
    allowed = set(DEFAULTS.keys())
    for k, v in patch.items():
        if k in allowed:
            current[k] = v if v is not None else current.get(k)
    SETTINGS_PATH.write_text(json.dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
    return current

def masked_settings(settings: Dict[str, Any]) -> Dict[str, Any]:
    s = dict(settings)
    k = s.get("openai_api_key", "") or ""
    if k:
        s["openai_api_key"] = (k[:4] + "…" + k[-4:]) if len(k) >= 10 else "****"
    else:
        s["openai_api_key"] = ""
    return s

async def openai_chat(messages: List[Dict[str, str]], settings: Dict[str, Any]) -> str:
    api_key = (settings.get("openai_api_key") or "").strip()
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY missing. Set it in Settings first.")
    base_url = (settings.get("openai_base_url") or "https://api.openai.com/v1").rstrip("/")
    model = (settings.get("openai_model") or "gpt-4o-mini").strip()

    url = f"{base_url}/chat/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    payload = {
        "model": model,
        "messages": messages,
        "temperature": 0.3,
    }

    timeout = httpx.Timeout(60.0, connect=20.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        r = await client.post(url, headers=headers, json=payload)
        if r.status_code >= 400:
            # keep error concise
            raise RuntimeError(f"LLM error {r.status_code}: {r.text[:500]}")
        data = r.json()
        return (data.get("choices", [{}])[0].get("message", {}) or {}).get("content", "") or ""
