FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install dependencies
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the AI service source code
COPY . .

# Expose the port used by the AI service (adjust if needed)
EXPOSE 5050

# Run the service
CMD ["python", "main.py"]