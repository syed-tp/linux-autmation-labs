#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <copy|sync> <source> <destination>" >&2
    exit 2
fi

OPERATION="$1"
SOURCE="$2"
DESTINATION="$3"

case "$OPERATION" in
    copy|sync) ;;
    *)
        echo "Operation must be copy or sync." >&2
        exit 2
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$SCRIPT_DIR/logs"

# S3 settings and credentials come from exported RCLONE_S3_* variables.
# /dev/null ensures that no saved rclone.conf is used.
rclone --config /dev/null "$OPERATION" "$SOURCE" "$DESTINATION" \
    --progress \
    --log-level INFO \
    --log-file "$SCRIPT_DIR/logs/transfer.log"
