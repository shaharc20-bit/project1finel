FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Linux version of speedtest (speedtest.exe works only on Windows)
ADD https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz /tmp/speedtest.tgz
RUN tar -xzf /tmp/speedtest.tgz -C /usr/local/bin speedtest

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5001

WORKDIR /app
COPY --from=builder /install /usr/local
COPY --from=builder /usr/local/bin/speedtest /usr/local/bin/speedtest
COPY one.py .
COPY templates/ templates/

RUN useradd --create-home --uid 10001 appuser
USER 10001

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5001/health')"]

CMD ["python", "one.py"]
