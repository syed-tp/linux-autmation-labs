#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ "$EUID" -ne 0 ]]; then
    echo "Run: sudo bash $PROJECT_DIR/setup.sh" >&2
    exit 1
fi
command -v python3 >/dev/null
command -v systemctl >/dev/null
command -v useradd >/dev/null
if [[ "$(ps -p 1 -o comm=)" != systemd ]]; then
    echo "systemd must be running as PID 1." >&2
    exit 1
fi
if ! id cricket-worker >/dev/null 2>&1; then
    useradd --system --user-group --home-dir /nonexistent --no-create-home --shell /usr/sbin/nologin cricket-worker
fi
if [[ "$(id -u cricket-worker)" == 0 ]]; then
    echo "Refusing to use a root service account." >&2
    exit 1
fi
install -d -o root -g root -m 755 /opt/cricket-worker
install -o root -g root -m 644 "$PROJECT_DIR/app.py" /opt/cricket-worker/app.py
# Fill in the application directory and install the service.
sed 's|@APP_DIR@|/opt/cricket-worker|g' "$PROJECT_DIR/cricket-worker.service.template" > /etc/systemd/system/cricket-worker.service
chmod 644 /etc/systemd/system/cricket-worker.service
# Preserve local configuration on subsequent installs.
if [[ ! -e /etc/cricket-worker.env ]]; then
    install -o root -g root -m 644 "$PROJECT_DIR/worker.env.example" /etc/cricket-worker.env
fi
systemd-analyze verify /etc/systemd/system/cricket-worker.service
systemctl daemon-reload
echo "Installed. Existing environment configuration was preserved."
echo "Start now and enable on boot: sudo systemctl enable --now cricket-worker"
echo "Follow logs: sudo journalctl -u cricket-worker -f"
