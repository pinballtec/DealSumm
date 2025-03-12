FROM python:3.9-slim

# Install ocrmypdf, Tesseract, Ghostscript.
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    libtesseract-dev \
    ghostscript \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies: ocrmypdf for OCR, boto3 for S3, and optionally awscli
RUN pip install --no-cache-dir ocrmypdf boto3 awscli

WORKDIR /app

# Copy our Python script into the container
COPY process_s3.py /app/

CMD ["python", "process_s3.py"]
