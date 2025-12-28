from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

# API app (نخلي الدوكس تحت /api/docs حتى ما تتعارض مع React على "/")
api = FastAPI(title="nova-forge-api", docs_url="/docs", redoc_url="/redoc", openapi_url="/openapi.json")

@api.get("/ping")
def ping():
    return {"pong": True}

app = FastAPI(title="nova-forge")

@app.get("/healthz")
def healthz():
    return {"service": "nova-forge", "status": "ok"}

# mount API under /api
app.mount("/api", api)

# Serve React build (Vite dist)
FRONTEND_DIST = Path(__file__).resolve().parents[2] / "frontend" / "dist"

if FRONTEND_DIST.exists():
    app.mount("/", StaticFiles(directory=str(FRONTEND_DIST), html=True), name="frontend")

    # SPA fallback (React Router refresh)
    @app.get("/{full_path:path}")
    def spa_fallback(full_path: str):
        index = FRONTEND_DIST / "index.html"
        if index.exists():
            return FileResponse(str(index))
        return JSONResponse({"error": "frontend index.html missing"}, status_code=500)
else:
    # لو ما في dist، على الأقل ما نخلي root فاضي
    @app.get("/")
    def root():
        return {"service": "nova-forge", "status": "ok", "frontend": "missing_dist"}
