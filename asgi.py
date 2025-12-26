from fastapi import FastAPI
app = FastAPI(title="Nova-Forge (Atlas)")

@app.get("/health")
def health():
    return {"ok": True}
