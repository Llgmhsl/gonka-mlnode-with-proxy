ARG BASE_IMAGE_VERSION=3.0.10
FROM ghcr.io/product-science/mlnode:${BASE_IMAGE_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx \
        gettext-base \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/cache/nginx /var/run/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080 5050

ENV UVICORN_CMD="uvicorn api.app:app --host=0.0.0.0 --port=8000"
CMD ["bash", "-lc", "nginx -g 'daemon off;' & ${UVICORN_CMD}"]