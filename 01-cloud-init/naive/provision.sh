#!/usr/bin/env bash
set -euo pipefail

echo "Starting naive server provisioning..."

# Update and install packages
sudo apt-get update
sudo apt-get install -y git curl ffmpeg docker.io

# Ensure Docker is running and enabled on boot
sudo systemctl enable --now docker

# Build application image
sudo docker build -t testpress-app /home/ubuntu/app

# Replace existing container if present (safe to rerun)
sudo docker rm -f testpress-app 2>/dev/null || true

# Start application
sudo docker run -d \
  --name testpress-app \
  --restart unless-stopped \
  -p 8080:8080 \
  testpress-app

echo "Naive provisioning completed successfully!"