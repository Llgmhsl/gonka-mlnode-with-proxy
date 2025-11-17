# Unified ML for Gonka + Nginx Container

This container targets environments where only Docker deployment is available (RunPod, self-managed GPU nodes, etc.). It bundles the inference stack from `ghcr.io/product-science/mlnode:3.0.10` with Nginx-based reverse proxying in a single GPU-ready image.

Key characteristics:

- Base image remains `mlnode`, so all CUDA/Python tooling from upstream is available out of the box.
- We do **not** change the upstream entrypoint — all environment preparation (user `appuser`, `PYTHONPATH`, etc.) remains as in the original image.
- Nginx and uvicorn are started with a single line in `CMD`: Nginx runs in the background, uvicorn runs in the foreground.

## Usage

### Pre-built image (GHCR)

```bash
# latest version from the main branch
docker pull ghcr.io/korchasa/gonka-mlnode-with-proxy:latest

docker run --gpus all \
  -p 8080:8080 -p 5050:5050 \
  ghcr.io/korchasa/gonka-mlnode-with-proxy:latest
```

Port `8080` is used for uvicorn, `5050` for the inference endpoint served through Nginx. Nginx access/error logs stream to STDOUT/STDERR via symlinks, so hosting platforms capture them automatically.

## Ports

The container exposes two main ports through Nginx reverse proxy:

| Port | Service | Internal Target | Description |
|------|---------|-----------------|-------------|
| `8080` | Nginx → Uvicorn | `localhost:8080` | Main API endpoint, FastAPI application |
| `5050` | Nginx → Inference | `localhost:5000` | ML inference endpoint |

### Port Configuration

- **Port 8080**: Handles all FastAPI routes, including API endpoints, health checks, and application routes
- **Port 5050**: Dedicated to ML inference requests, routing to the model's internal server
- Both ports support versioned routes (`/v3.0.8/`) and backward-compatible routes (`/`)
- Nginx acts as a reverse proxy, forwarding requests to the appropriate internal services

## Process layout

Container process tree is very simple:

- PID 1 — upstream entrypoint from `mlnode` (creates user, sets environment variables, etc.).
- Child — `bash -lc "nginx -g 'daemon off;' & ${UVICORN_CMD}"`.
- Within this command:
  - `nginx` runs in the background (`daemon off;`), logs go to STDOUT/STDERR via symlinks.
  - `uvicorn` runs in the foreground and is the main container process.

## Environment Variables

| Variable     | Default                                          | Description                                    |
|--------------|--------------------------------------------------|------------------------------------------------|
| `UVICORN_CMD`| `uvicorn api.app:app --host=0.0.0.0 --port=8080` | Command executed inside the uvicorn service    |
| `NGINX_CMD`  | `nginx -g 'daemon off;'`                         | Command executed inside the nginx service      |
| `HF_HOME`    | `~/.cache`                                       | HuggingFace cache root (forwarded to uvicorn)  |

Example (custom uvicorn port and HuggingFace cache):

```bash
docker run --gpus all \
  -p 9000:9000 -p 5050:5050 \
  -e UVICORN_CMD="uvicorn api.app:app --host=0.0.0.0 --port=9000" \
  -e HF_HOME=/data/hf-cache \
  ghcr.io/korchasa/gonka-mlnode-with-proxy:latest
```

## Useful Links

- [Official Documentation: Multiple nodes](https://gonka.ai/host/multiple-nodes/)
- [Network Node API](https://gonka.ai/host/network-node-api/)