FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/nsonaniya2010/SubDomainizer.git .
RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python3", "SubDomainizer.py"]