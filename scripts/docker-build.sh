#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="muchtodo-backend:local"

echo "Building backend image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" .
echo "Done."

