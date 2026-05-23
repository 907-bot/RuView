#!/usr/bin/env bash
set -euo pipefail

echo "Starting ruview backend entrypoint"
echo "ENVIRONMENT=${ENVIRONMENT:-not-set}"
echo "DEMO_MODE=${DEMO_MODE:-not-set}"
echo "WORKERS=${WORKERS:-not-set}"
echo "Listening on 0.0.0.0:8000"

# Print python info for debugging
PYTHON_CMD=$(command -v python3 || command -v python || true)
echo "python cmd: ${PYTHON_CMD}"
${PYTHON_CMD} --version || true

echo "Checking gunicorn availability..."
${PYTHON_CMD} -c "import importlib, sys
try:
  importlib.import_module('gunicorn')
  print('gunicorn module OK')
except Exception as e:
  print('gunicorn import failed:', e)
  sys.exit(127)
"

# Default worker count fallback
if [ -z "${WORKERS:-}" ] || [ "$WORKERS" = "not-set" ]; then
  export WORKERS=1
fi

if [ -n "${PYTHON_CMD}" ]; then
  exec "${PYTHON_CMD}" -m gunicorn -c backend/gunicorn_conf.py backend.main:app
else
  echo "No python executable found in PATH" >&2
  exit 127
fi
