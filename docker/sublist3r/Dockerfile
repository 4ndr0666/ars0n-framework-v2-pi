FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/aboul3la/Sublist3r.git .
RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python3", "sublist3r.py"]