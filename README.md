# Linux Automation Labs

Hands-on exercises for setting up Linux servers, transferring files, and managing processes with cloud-init, rclone, and systemd. Everything runs locally, without paid cloud services.

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

### 3. Process Management & systemd

Run a cricket commentary worker, handle shutdown signals, and use systemd to manage restarts, logs, and resource limits. Includes a pitch service dependency experiment.

- [Setup and usage](03-process-management-systemd/README.md)
- [Walkthrough and screenshots](03-process-management-systemd/experiments.md)
- [Commentary service template](03-process-management-systemd/cricket-worker.service.template)
- [Pitch service template](03-process-management-systemd/cricket-pitch.service.template)

Requires Linux with systemd, including WSL with systemd enabled. This lab has its own setup script; some tests and screenshots are still marked as pending in the walkthrough.
