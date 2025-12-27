import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, PlainTextResponse

app = FastAPI(title="Nova-Forge (Atlas)")

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

BASE_DIR = os.path.dirname(__file__)
FRONTEND_DIST = os.path.join(BASE_DIR, "frontend", "dist")
INDEX_HTML = os.path.join(FRONTEND_DIST, "index.html")

# Mount full dist at root if it exists
if os.path.isfile(INDEX_HTML):
    app.mount("/", StaticFiles(directory=FRONTEND_DIST, html=True), name="frontend")
else:
    @app.get("/")
    def root_missing_ui():
        return PlainTextResponse(
            "OK (backend). UI missing: /app/frontend/dist/index.html not found inside container.",
            status_code=200,
        )

