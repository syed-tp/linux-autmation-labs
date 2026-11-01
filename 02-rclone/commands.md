# Commands

Run from the repository root. Set up the folders and MinIO as described in the [README](README.md).

## Local files

### List and copy

```bash
rclone ls 02-rclone/data/source
rclone copy 02-rclone/data/source 02-rclone/data/destination --progress
```

`ls` shows sizes in bytes. Copy transfers source contents, skips unchanged files, and keeps destination-only files.

### Check

```bash
rclone check 02-rclone/data/source 02-rclone/data/destination
rclone check 02-rclone/data/source 02-rclone/data/destination --one-way
```

Check compares files without changing them. One-way checks that all source files exist and match at the destination, ignoring destination extras.

### Sync and dry run

```bash
echo "Destination only" > 02-rclone/data/destination/extra.txt
rclone sync 02-rclone/data/source 02-rclone/data/destination --dry-run
rclone sync 02-rclone/data/source 02-rclone/data/destination
```

Dry run previews changes. Actual sync deletes extra.txt to make destination match source. Source comes first; reversing the paths changes which location is modified.

### Move

```bash
echo "Move example" > 02-rclone/data/source/move-me.txt
rclone move 02-rclone/data/source 02-rclone/data/destination \
  --include 'move-me.txt' --progress
```

Transfers only move-me.txt, then removes it from source after success.

### Create a large test file

```bash
dd if=/dev/urandom of=02-rclone/data/source/large-test.bin \
  bs=1M count=100 status=progress
rclone copy 02-rclone/data/source 02-rclone/data/destination --progress
```

Creates 100 MiB of random data. In dd, `if` is input, `of` is output, `bs` is block size, and `count` is the number of blocks. The output file is overwritten if it exists.

## Working with S3

### Connect without rclone.conf

In a second terminal, enter the same credentials used to start MinIO:

```bash
read -r -p "MinIO username: " RCLONE_S3_ACCESS_KEY_ID
read -r -s -p "MinIO password: " RCLONE_S3_SECRET_ACCESS_KEY
echo
export RCLONE_S3_ACCESS_KEY_ID RCLONE_S3_SECRET_ACCESS_KEY
export RCLONE_S3_PROVIDER=Minio
export RCLONE_S3_ENDPOINT=http://127.0.0.1:9000
```

`:s3:` creates an on-the-fly connection. `--config /dev/null` uses an empty configuration instead of saved remotes. Settings and credentials still have to be supplied.

### Create and list buckets

```bash
rclone --config /dev/null mkdir :s3:testpress-lab
rclone --config /dev/null lsd :s3:
```

### Upload and list objects

```bash
rclone --config /dev/null copy \
  02-rclone/data/source :s3:testpress-lab --progress
rclone --config /dev/null ls :s3:testpress-lab
```

### Download and check

```bash
rclone --config /dev/null copy \
  :s3:testpress-lab 02-rclone/data/downloaded --progress
rclone check 02-rclone/data/source 02-rclone/data/downloaded
```

Download is copy in the reverse direction: storage becomes the source and the local folder becomes the destination. Do this round-trip check before creating more source files, or download again first.

### Copy between buckets

```bash
rclone --config /dev/null mkdir :s3:testpress-backup
rclone --config /dev/null copy \
  :s3:testpress-lab :s3:testpress-backup --progress
rclone --config /dev/null ls :s3:testpress-backup
```

The source bucket remains unchanged.

### Delete one object

```bash
echo "Delete test" > /tmp/rclone-delete-test.txt
rclone --config /dev/null copyto \
  /tmp/rclone-delete-test.txt :s3:testpress-lab/delete-test.txt
rclone --config /dev/null deletefile \
  :s3:testpress-lab/delete-test.txt --dry-run
rclone --config /dev/null deletefile \
  :s3:testpress-lab/delete-test.txt
```

Copyto sets the exact destination object name. Deletefile removes only that object.

### Large upload and interruption

```bash
dd if=/dev/urandom of=02-rclone/data/source/large-1gb.bin \
  bs=1M count=1024 status=progress

rclone --config /dev/null copy \
  02-rclone/data/source :s3:testpress-lab \
  --transfers 2 --bwlimit 20M \
  --retries 3 --low-level-retries 5 --progress
```

Creates a 1 GiB file. Press Ctrl+C during upload, then run the same copy command again.

- `--transfers 2`: up to two files at once, not two parts of one file.
- `--bwlimit 20M`: total bandwidth limit of about 20 MiB/s.
- `--retries 3`: overall attempt count.
- `--low-level-retries 5`: retries for individual failed operations.
- `--progress`: bytes, speed, elapsed time, and estimated time remaining.

### Verify uploaded contents

```bash
rclone --config /dev/null check \
  02-rclone/data/source :s3:testpress-lab --one-way --download
```

Reads remote contents for comparison without saving a local copy. This avoids relying on a shared checksum for multipart uploads. It reads the full data and may take time.

### Supply settings as flags

```bash
rclone --config /dev/null \
  --s3-provider Minio \
  --s3-endpoint http://127.0.0.1:9000 \
  lsd :s3:
```

Credentials still come from the exported variables. Change the endpoint and supply its matching credentials for another storage service.

## Transfer script

```bash
bash 02-rclone/transfer.sh copy 02-rclone/data/source :s3:testpress-lab

# Preview before running sync:
rclone --config /dev/null sync \
  02-rclone/data/source 02-rclone/data/destination --dry-run
bash 02-rclone/transfer.sh sync \
  02-rclone/data/source 02-rclone/data/destination
```

The script accepts operation, source, and destination. It logs activity and errors to `02-rclone/logs/transfer.log`. Run `echo $?` immediately after it to see its exit code; zero means success.
