#!/usr/bin/env bash
set -euo pipefail

# Generate mongodb keyfile if missing (needed by your compose mongo replSet config)
if [ ! -f "./mongodb.key" ]; then
  echo "Generating mongodb.key..."
  openssl rand -base64 756 > mongodb.key
  chmod 400 mongodb.key
fi

echo "Starting docker compose..."
docker compose up -d

echo "Containers:"
docker ps

echo "Health check:"
curl -i http://localhost:8080/health || true

