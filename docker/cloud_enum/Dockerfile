FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/initstring/cloud_enum.git .
RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python3", "cloud_enum.py"]