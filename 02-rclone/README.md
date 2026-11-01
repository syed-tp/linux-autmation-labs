# Rclone

Transfer, sync, and verify files between local folders and a local MinIO S3 endpoint.

## Setup

Run from the repository root on Ubuntu:

```bash
bash setup.sh
rclone version
```

Create the local test files:

```bash
mkdir -p 02-rclone/data/source/notes 02-rclone/data/destination
echo "Hello from Testpress" > 02-rclone/data/source/hello.txt
echo "Learning rclone" > 02-rclone/data/source/notes/lesson.txt
```

## Start MinIO

```bash
bash 02-rclone/setup.sh
```

The script builds MinIO on the first run and asks for credentials. It runs directly on the host, without Docker, and stores objects in `02-rclone/data/minio`.

Keep that terminal open. In another terminal, check readiness:

```bash
curl -f http://127.0.0.1:9000/minio/health/ready
```

The S3 endpoint is `http://127.0.0.1:9000`. Ctrl+C stops the server; stored data remains. Use the same credentials on restart.

## Documentation

- [Commands](commands.md): local operations, S3 connections, large transfers, and script usage.
- [Results and learnings](results.md): observations, challenges, and remaining checks.

## Transfer script

```bash
bash 02-rclone/transfer.sh copy SOURCE DESTINATION
bash 02-rclone/transfer.sh sync SOURCE DESTINATION
```

For S3, export the variables shown in [commands.md](commands.md#connect-without-rcloneconf). The script shows progress, logs to `02-rclone/logs/transfer.log`, and returns a failure exit code when rclone fails. It uses no saved configuration file.

Preview sync with `--dry-run` before using the script: destination-only files will be deleted.
