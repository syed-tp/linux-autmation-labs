
#!/usr/bin/env bash
set -euo pipefail

echo "=================================="
echo " Linux Automation Labs - Setup"
echo "=================================="

has_command() {
    command -v "$1" >/dev/null 2>&1
}

OS="$(uname -s)"

case "$OS" in
    Darwin)
        echo "[INFO] Detected macOS"

        if ! has_command brew; then
            echo "[ERROR] Homebrew is required."
            echo "Install Homebrew from https://brew.sh"
            exit 1
        fi

        for cmd in git curl; do
            if ! has_command "$cmd"; then
                echo "[INFO] Installing $cmd..."
                brew install "$cmd"
            fi
        done

        if ! has_command multipass; then
            echo "[INFO] Installing Multipass..."
            brew install --cask multipass
        fi
        ;;

    Linux)
        if [[ ! -f /etc/os-release ]]; then
            echo "[ERROR] Cannot identify Linux distribution."
            exit 1
        fi

        source /etc/os-release

        if [[ "$ID" != "ubuntu" ]]; then
            echo "[ERROR] Only Ubuntu is supported currently."
            exit 1
        fi

        echo "[INFO] Detected Ubuntu $VERSION_ID"

        sudo apt-get update

        sudo apt-get install -y \
            git \
            curl \
            openssh-client \
            ca-certificates \
            snapd

        if ! has_command multipass; then
            echo "[INFO] Installing Multipass..."
            sudo snap install multipass
        fi
        ;;

    *)
        echo "[ERROR] Unsupported OS: $OS"
        exit 1
        ;;
esac

echo ""
echo "[INFO] Verifying prerequisites..."

for cmd in git curl ssh multipass; do
    if has_command "$cmd"; then
        echo "[OK] $cmd"
    else
        echo "[ERROR] $cmd is unavailable"
        exit 1
    fi
done

echo ""
echo "[INFO] Multipass version:"
multipass version

echo ""
echo "[SUCCESS] Setup completed!"
