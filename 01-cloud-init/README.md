# Cloud-init learning notes

## Goal

Provision a local Ubuntu 24.04 VM automatically: install packages, create a user, write configuration, and run our Dockerized Testpress app.

The naive approach transfers files and runs a script after VM creation. Here, cloud-init performs the setup during first boot using [cloud-init.yaml](cloud-init/cloud-init.yaml).

## What the YAML does

- `#cloud-config`: identifies a cloud-init configuration.
- `package_update`: refreshes the package index.
- `packages`: installs Docker, Git, curl, and FFmpeg.
- `groups` and `users`: creates testpress with Docker access and a locked password. Docker group access effectively grants root privileges.
- `write_files`: creates `/opt/testpress/app.env` with sample variables.
- `runcmd`: starts Docker, clones our public repository, builds the image, and runs the container.

### File notes

`owner: testpress:testpress` sets the file's user and group, not the parent directory's ownership.

`permissions: '0640'` means owner read/write, group read, others no access. Read = 4, write = 2, execute = 1.

`defer: true` waits until the Final stage, after user creation. `content: |` writes multiline text.

The app.env variables are samples; our app does not read them. Its greeting is already in the Python code.

### Docker notes

- `systemctl enable --now docker`: starts Docker now and on future boots.
- `docker build -t testpress-app ...`: builds our existing app/Dockerfile.
- `-d`: runs the container in the background.
- `-p 8080:8080`: maps VM port 8080 to container port 8080.
- `--env-file`: passes variables into the container.
- `--restart unless-stopped`: restarts after failure or reboot unless deliberately stopped.

## Launch

Requires Multipass, virtualization support, and internet access. Run in Bash from the repository root:

```bash
multipass launch 24.04 \
  --name testpress-lab \
  --cpus 2 \
  --memory 2G \
  --disk 20G \
  --cloud-init 01-cloud-init/cloud-init/cloud-init.yaml

multipass exec testpress-lab -- cloud-init status --wait
```

Expected: `status: done`. No manual installation inside the VM is needed.

## Verify

Find the VM's IPv4 address:

```bash
multipass info testpress-lab
curl http://<VM_IP>:8080
```

Expected response: `Hello from Testpress!`. The host must be able to reach the VM network.

Check packages, user access, and file permissions:

```bash
multipass exec testpress-lab -- dpkg-query -W docker.io git curl ffmpeg
multipass exec testpress-lab -- id testpress
multipass exec testpress-lab -- sudo -u testpress docker ps
multipass exec testpress-lab -- stat -c '%U:%G %a %n' /opt/testpress/app.env
```

Expected file details: `testpress:testpress 640 /opt/testpress/app.env`.

Check automatic startup after reboot:

```bash
multipass restart testpress-lab
multipass exec testpress-lab -- cloud-init status --wait
multipass exec testpress-lab -- curl --retry 30 --retry-connrefused --retry-delay 2 -fsS http://localhost:8080
```

To test crash recovery, allow the app to run for ten seconds, then terminate its process:

```bash
multipass exec testpress-lab -- sudo docker exec testpress-app python -c 'import os, signal; os.kill(1, signal.SIGKILL)'
multipass exec testpress-lab -- curl --retry 30 --retry-connrefused --retry-delay 2 -fsS http://localhost:8080
```

Save your actual command outputs for submission. Results above are expected outputs, not recorded verification.

## How cloud-init runs

| Stage | Purpose |
| --- | --- |
| Detect | Decide whether cloud-init should run |
| Local | Discover local data and prepare networking |
| Network | Process user-data and early modules, including users |
| Config | Prepare configuration, including the runcmd script |
| Final | Install packages, write deferred files, and execute the script |

Our provisioning modules normally run once per instance. Rebooting does not clone or build again; Docker starts the existing container. Modules such as bootcmd can run every boot.

Cloud-init compares the datasource instance ID with cached state under `/var/lib/cloud` and tracks completed modules. A new instance ID or missing cache indicates first boot. Changing the host YAML does not reconfigure an existing VM automatically.

## Remaining work and concepts

- Repeated execution is deferred: forcing our commands to rerun would fail at the existing clone directory and container name. Normal reboot behavior is different from command idempotency.
- Cloning the default branch uses its current code; pinning a commit can improve reproducibility later.
- Cloud-init configures the VM. A Dockerfile builds the application image.
- User-data is our YAML; metadata describes the instance, including its ID. Multipass supplies metadata. QEMU can use a NoCloud seed disk containing user-data and meta-data.
- A dedicated systemd app service and health check are optional bonuses, not implemented here.

## Troubleshooting

```bash
multipass exec testpress-lab -- sudo tail -n 80 /var/log/cloud-init-output.log
multipass exec testpress-lab -- sudo docker ps -a
multipass exec testpress-lab -- sudo docker logs testpress-app
```

## References

- [Cloud-init boot stages](https://docs.cloud-init.io/en/latest/explanation/boot.html)
- [First boot determination](https://docs.cloud-init.io/en/latest/explanation/first_boot.html)
- [Multipass with cloud-init](https://canonical.com/multipass/docs/stable/how-to-guides/manage-instances/launch-customized-instances-with-multipass-and-cloud-init/)
