# ---------- Frontend build ----------
FROM node:20-alpine AS frontend
WORKDIR /fe
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ---------- Backend runtime ----------
FROM python:3.11-slim AS runtime
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY . /app
# bring built frontend dist into image
COPY --from=frontend /fe/dist /app/frontend/dist

# Render sets PORT
CMD ["sh","-c","python -m uvicorn asgi:app --host 0.0.0.0 --port ${PORT:-8000}"]
