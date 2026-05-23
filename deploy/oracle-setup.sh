#!/usr/bin/env bash
set -euo pipefail
echo "This script outlines steps to deploy on an Oracle Always Free VM."
echo "1) Create ARM instance via Oracle Cloud console."
echo "2) SSH into the VM and install Docker:"
echo "   curl -fsSL https://get.docker.com | sh"
echo "3) Clone repo and run: docker compose up -d"
