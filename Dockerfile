FROM python:3.12-alpine

LABEL org.opencontainers.image.title="ysp-live"

WORKDIR /app

COPY ysp-live.py /app/ysp-live.py

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    PORT=8766 \
    HOST=0.0.0.0

EXPOSE 8766

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O - "http://127.0.0.1:${PORT}/health" || exit 1

CMD ["python", "-u", "/app/ysp-live.py"]
