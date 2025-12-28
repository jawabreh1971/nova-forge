from __future__ import annotations
import json
import os
import time
from typing import Any, Dict

def append_audit(path: str, event: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    payload = {"ts": int(time.time() * 1000), **event}
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")

