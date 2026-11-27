FROM python:3.12-alpine

LABEL org.opencontainers.image.title="ysp-live" \
      org.opencontainers.image.description="央视频全频道直播代理 v11.3 (YSPTP 设备协议)" \
      org.opencontainers.image.version="11.3"

WORKDIR /app

# v11.3 is pure standard library; node is only needed for the optional
# Web WASM companion engine (4th-layer fallback). It is installed but the
# container runs fine without the engine file.
RUN apk add --no-cache nodejs tzdata ca-certificates \
    && mkdir -p /data

COPY ysp-live.py /app/ysp-live.py

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    PORT=8767 \
    YSP_DATA_DIR=/data \
    YSP_LINKS_PER_DEVICE=6 \
    YSP_ZAP_DEBOUNCE=0

VOLUME ["/data"]

EXPOSE 8767

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q -O - "http://127.0.0.1:${PORT}/health" || exit 1

# Optional flags can be appended, e.g.:
#   docker run ... ysp-live:11.3 --no-4k
#   docker run ... ysp-live:11.3 --only-4k
CMD ["sh", "-c", "python -u /app/ysp-live.py ${PORT:-8767} --bind 0.0.0.0 $YSP_EXTRA_ARGS"]
