
#!/usr/bin/env bash
set -euo pipefail

VM_NAME="naive-lab"
UBUNTU_VERSION="24.04"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROVISION_SCRIPT="$SCRIPT_DIR/provision.sh"
APP_DIR="$PROJECT_ROOT/app"

# Verify prerequisites
if ! command -v multipass >/dev/null 2>&1; then
    echo "Error: Multipass is not installed."
    exit 1
fi

if [[ ! -f "$PROVISION_SCRIPT" ]]; then
    echo "Error: provision.sh not found."
    exit 1
fi

if [[ ! -f "$APP_DIR/Dockerfile" || ! -f "$APP_DIR/server.py" ]]; then
    echo "Error: Application files not found in $APP_DIR"
    exit 1
fi

# Prevent duplicate VM creation
if multipass info "$VM_NAME" >/dev/null 2>&1; then
    echo "Error: VM '$VM_NAME' already exists."
    exit 1
fi

# Create VM
echo "Creating Ubuntu VM: $VM_NAME"

multipass launch "$UBUNTU_VERSION" \
    --name "$VM_NAME" \
    --cpus 2 \
    --memory 2G \
    --disk 20G

# Wait for VM initialization
echo "Waiting for Ubuntu to become ready..."
multipass exec "$VM_NAME" -- cloud-init status --wait

# Transfer provisioning script
echo "Transferring provision.sh..."

multipass transfer \
    "$PROVISION_SCRIPT" \
    "$VM_NAME:/home/ubuntu/provision.sh"

# Transfer application
echo "Transferring application..."

multipass transfer -r \
    "$APP_DIR" \
    "$VM_NAME:/home/ubuntu/"

# Execute provisioning script
echo "Provisioning Ubuntu..."

multipass exec "$VM_NAME" -- \
    bash /home/ubuntu/provision.sh

# Verify application
echo "Verifying application..."

multipass exec "$VM_NAME" -- \
    curl --fail --silent --show-error \
    http://localhost:8080

echo ""
echo "VM provisioned successfully!"
multipass info "$VM_NAME"
