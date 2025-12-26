FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# Render sets PORT env var at runtime
CMD ["sh","-c","python -m uvicorn asgi:app --host 0.0.0.0 --port ${PORT:-8000}"]
