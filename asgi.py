import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import PlainTextResponse

app = FastAPI(title="Nova-Forge (Atlas)")

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

BASE_DIR = os.path.dirname(__file__)
FRONTEND_DIST = os.path.join(BASE_DIR, "frontend", "dist")
INDEX_HTML = os.path.join(FRONTEND_DIST, "index.html")

# Serve React build at root
if os.path.isfile(INDEX_HTML):
    app.mount("/", StaticFiles(directory=FRONTEND_DIST, html=True), name="frontend")
else:
    @app.get("/")
    def root_backend_only():
        return PlainTextResponse(
            f"OK (backend). UI missing at: {INDEX_HTML}",
            status_code=200
        )

