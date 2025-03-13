FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    libtesseract-dev \
    ghostscript \
    wget \
    jq && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir ocrmypdf boto3 awscli

WORKDIR /app

COPY ocr_worker.py /app/

CMD ["python", "ocr_worker.py"]
