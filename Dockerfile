FROM node:20-alpine AS frontend
WORKDIR /fe
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM python:3.11-slim
WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app
COPY --from=frontend /fe/dist /app/frontend/dist

# HARD ASSERT: fail build if UI missing
RUN test -f /app/frontend/dist/index.html

CMD ["sh","-c","python -m uvicorn asgi:app --host 0.0.0.0 --port ${PORT:-8000}"]

