FROM python:3.11-slim AS base

# Set working directory
WORKDIR /app

# Install system dependencies for compiling Python packages and libpq for Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency specification and install dependencies
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose API port
EXPOSE 8443

# Start the FastAPI server (adjust the command to match your app's entry point)
CMD ["python", "main.py"]