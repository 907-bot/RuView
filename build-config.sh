#!/usr/bin/env bash
set -euo pipefail
# This script creates frontend/config.js during build time with BACKEND_URL
BACKEND_URL=${BACKEND_URL:-""}
cat > frontend/config.js <<EOF
window.__ENV = {
  BACKEND_URL: "${BACKEND_URL}"
};
EOF
echo "wrote frontend/config.js (BACKEND_URL=${BACKEND_URL})"
