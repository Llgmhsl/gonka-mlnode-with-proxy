ARG BASE_IMAGE_VERSION=3.0.11-post1
FROM ghcr.io/product-science/mlnode:${BASE_IMAGE_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx \
        gettext-base \
        screen \
        htop \
        ssh \
        iputils-ping \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/cache/nginx /var/run/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080 5050

# Health check script
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /healthcheck.sh

# Start script: activates venv, sets PYTHONPATH, runs nginx + uvicorn

COPY start.sh /root/start.sh
RUN chmod +x /start.sh

# Do not inherit upstream entrypoint to avoid double execution
ENTRYPOINT []
