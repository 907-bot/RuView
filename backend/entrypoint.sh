#!/usr/bin/env bash
set -euo pipefail

echo "Starting ruview backend entrypoint"
echo "ENVIRONMENT=${ENVIRONMENT:-not-set}"
echo "DEMO_MODE=${DEMO_MODE:-not-set}"
echo "WORKERS=${WORKERS:-not-set}"
echo "Listening on 0.0.0.0:8000"

# Default worker count fallback
if [ -z "${WORKERS:-}" ] || [ "$WORKERS" = "not-set" ]; then
  export WORKERS=1
fi

exec gunicorn -c backend/gunicorn_conf.py backend.main:app
