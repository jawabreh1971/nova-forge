import os
from fastapi import APIRouter

router = APIRouter()

def _read_git_sha() -> str:
    sha = os.getenv("GIT_SHA")
    if sha:
        return sha
    try:
        with open("GIT_SHA.txt", "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return "unknown"

@router.get("/api/version")
def version():
    return {
        "git_sha": _read_git_sha(),
        "service": os.getenv("RENDER_SERVICE_NAME", "local"),
        "env": os.getenv("RENDER", "false"),
    }
