# Stage 1
FROM python:3.11-slim as builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /app/
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Stage 2
FROM python:3.11-slim

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY send_ocr_request.py .

ENTRYPOINT ["python", "send_ocr_request.py"]
