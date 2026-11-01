#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIO_BIN="$SCRIPT_DIR/.local/bin/minio"

# Keep credentials out of the script and repository.
if [[ -z "${MINIO_ROOT_USER:-}" ]]; then
    read -r -p "MinIO username (at least 3 characters): " MINIO_ROOT_USER
fi
if [[ -z "${MINIO_ROOT_PASSWORD:-}" ]]; then
    read -r -s -p "MinIO password (at least 8 characters): " MINIO_ROOT_PASSWORD
    printf '\n'
fi
if [[ ${#MINIO_ROOT_USER} -lt 3 || ${#MINIO_ROOT_PASSWORD} -lt 8 ]]; then
    echo "Username must have at least 3 characters and password at least 8." >&2
    exit 1
fi
export MINIO_ROOT_USER MINIO_ROOT_PASSWORD

# Community MinIO is distributed as source; build it once for this lab.
if [[ ! -x "$MINIO_BIN" ]]; then
    if ! command -v go >/dev/null 2>&1; then
        echo "Installing Go and build tools (Ubuntu)..."
        sudo apt-get update
        sudo apt-get install -y golang-go build-essential ca-certificates
    fi
    mkdir -p "$SCRIPT_DIR/.local/bin"
    echo "Building MinIO; the first run downloads Go and dependencies..."
    GOBIN="$SCRIPT_DIR/.local/bin" GOTOOLCHAIN=go1.24.2 \
        go install github.com/minio/minio@RELEASE.2025-09-07T16-13-09Z
fi

mkdir -p "$SCRIPT_DIR/data/minio"
echo "Starting MinIO at http://127.0.0.1:9000 (Ctrl+C to stop)."
exec "$MINIO_BIN" server "$SCRIPT_DIR/data/minio" \
    --address 127.0.0.1:9000 --console-address 127.0.0.1:9001
