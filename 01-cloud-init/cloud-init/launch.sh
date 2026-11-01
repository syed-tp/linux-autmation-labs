#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

multipass launch 24.04 \
  --name testpress-lab \
  --cpus 2 \
  --memory 2G \
  --disk 20G \
  --timeout 900 \
  --cloud-init "$SCRIPT_DIR/cloud-init.yaml"

multipass exec testpress-lab -- cloud-init status --wait

multipass exec testpress-lab -- curl -fsS http://localhost:8080