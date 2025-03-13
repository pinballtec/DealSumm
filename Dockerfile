# Stage 1
FROM python:3.11-slim as builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN apt-get update && \
    apt-get install -y build-essential && \
    pip install --upgrade pip

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Stage 2
FROM python:3.9-slim

WORKDIR /app

COPY --from=0 /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY send_ocr_request.py /app/send_ocr_request.py

ENTRYPOINT ["python", "send_ocr_request.py"]
