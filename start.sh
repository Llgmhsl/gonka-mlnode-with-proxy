#!/bin/bash

# --- Original-like entrypoint steps (idempotent) ---
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1001}

if ! getent group appgroup >/dev/null; then
  echo "Creating group 'appgroup'"
  groupadd -g "$HOST_GID" appgroup
else
  echo "Group 'appgroup' already exists"
fi

if ! id -u appuser >/dev/null 2>&1; then
  echo "Creating user 'appuser'"
  useradd -m -u "$HOST_UID" -g appgroup appuser
else
  echo "User 'appuser' already exists"
fi

# --- Activate venv if present ---
if [ -f "/app/packages/api/.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source /app/packages/api/.venv/bin/activate
fi

# --- Ensure PYTHONPATH includes api and common sources ---
PY_APP="/app"
PY_API="/app/packages/api/src"
PY_COMMON="/app/packages/common/src"

if [ -z "${PYTHONPATH:-}" ]; then
  export PYTHONPATH="${PY_APP}:${PY_API}:${PY_COMMON}"
else
  export PYTHONPATH="${PY_APP}:${PY_API}:${PY_COMMON}:${PYTHONPATH}"
fi

# --- Compose uvicorn command (can be overridden via env) ---
UVICORN_CMD_DEFAULT="uvicorn api.app:app --host=0.0.0.0 --port=8080"
UVICORN_CMD="${UVICORN_CMD:-$UVICORN_CMD_DEFAULT}"

# --- Start services ---
nginx -g 'daemon off;' &

# Run uvicorn in foreground, preserve signals
exec bash -lc "$UVICORN_CMD"


