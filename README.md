# Linux Automation Labs

Hands-on exercises for provisioning Linux servers and transferring files using cloud-init and rclone. Everything runs locally, without paid cloud services.

## Setup

Clone the repository and install the prerequisites:

```bash
git clone https://github.com/syed-tp/linux-autmation-labs.git
cd linux-autmation-labs
bash setup.sh
```

The setup script installs Git, curl, Multipass, and rclone on Ubuntu or macOS. macOS requires Homebrew; Ubuntu requires sudo access. Multipass needs virtualization support.

## Application

The [app](app/) is a small Python HTTP server that returns `Hello from Testpress!` on port 8080. Its [Dockerfile](app/Dockerfile) packages it using Python Alpine. The cloud-init exercise builds and runs it inside an Ubuntu VM.

## Exercises

### 1. Cloud-init

Provision an Ubuntu 24.04 VM with packages, a testpress user, an environment file, and the Dockerized app.

- [Setup and verification](01-cloud-init/README.md)
- [Cloud-init configuration](01-cloud-init/cloud-init/cloud-init.yaml)
- [Launch script](01-cloud-init/cloud-init/launch.sh)

### 2. Rclone

Copy, move, sync, and verify files locally and with a local MinIO S3 endpoint. Includes configuration-free connections and interrupted large-file transfers.

- [Commands and experiments](02-rclone/README.md)
- [MinIO setup script](02-rclone/setup.sh)
- [Transfer script](02-rclone/transfer.sh)

MinIO runs directly on the host. Its setup is separate from the root setup script.
