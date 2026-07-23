# Franchise Platform Orchestrator
# Lightweight Python service that coordinates specialized agents via Ollama

FROM python:3.12-slim

WORKDIR /app

# System deps (curl useful for health checks / debugging)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy orchestrator source
COPY . .

# The monorepo is mounted at runtime to /app (see docker-compose.yml)
# so all .md docs and prompts/ are available live.

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Default command: run the interactive orchestrator
CMD ["python", "main.py"]
