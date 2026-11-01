# Rclone

I used two local folders: source and destination. Source contains the files I want to transfer. It also has a notes subfolder to test nested files.

## List

```bash
rclone ls 02-rclone/data/source
```

Lists files and their sizes in bytes.

## Copy

```bash
rclone copy 02-rclone/data/source 02-rclone/data/destination --progress
```

Copies files without removing them from source. Unchanged files are skipped on the next run. Extra files in destination are kept.

## Check

```bash
rclone check 02-rclone/data/source 02-rclone/data/destination
```

Checks whether the files match. It does not copy or delete anything. My first check showed 0 differences and 2 matching files.

## Sync and dry run

```bash
rclone sync 02-rclone/data/source 02-rclone/data/destination --dry-run
```

Shows what sync would change without actually changing anything. I added extra.txt only in destination, and dry run showed it would be deleted.

```bash
rclone sync 02-rclone/data/source 02-rclone/data/destination
```

Makes destination match source. This deleted extra.txt. Source is unchanged, so the order of the paths matters.

## Move

```bash
rclone move 02-rclone/data/source 02-rclone/data/destination \
  --include 'move-me.txt' --progress
```

Moves only move-me.txt. After a successful transfer, it is removed from source and stays in destination.

## Check one way

```bash
rclone check 02-rclone/data/source 02-rclone/data/destination --one-way
```

Checks that destination has all source files and they match. If destination has extra files, they are ignored. Nothing is changed.

## Large test file

```bash
dd if=/dev/urandom of=02-rclone/data/source/large-test.bin \
  bs=1M count=100 status=progress
```

Creates a 100 MiB file for testing. dd reads random bytes from the input and writes them to the output file. It overwrites the output file if it already exists.

Local transfers do not need an rclone.conf file, so the missing config notice is okay.

## Working with S3

I used MinIO locally to try S3 operations without a cloud account. MinIO provides an S3-compatible API, so rclone talks to it like object storage even though the data stays on my machine.

A bucket is a container for objects. Paths such as notes/lesson.txt are object keys; they look like folders, but S3 does not store them as ordinary filesystem directories.

### Start MinIO

From the repository root:

```bash
bash 02-rclone/setup.sh
```

The script builds MinIO from source on the first run and asks for a username and password. It starts the S3 endpoint at http://127.0.0.1:9000 and keeps its data in 02-rclone/data/minio. No Docker is involved.

I kept this terminal open and used another terminal for rclone. Ctrl+C stops MinIO, but the stored files remain. Use the same credentials when starting it again.

Check that it is ready:

```bash
curl -f http://127.0.0.1:9000/minio/health/ready
```

This succeeded with no response text. Here, localhost is my own machine because MinIO runs directly on it.

### Connect without rclone.conf

Normally, rclone can save connections in rclone.conf. For this exercise I supplied settings through environment variables instead:

```bash
read -r -p "MinIO username: " RCLONE_S3_ACCESS_KEY_ID
read -r -s -p "MinIO password: " RCLONE_S3_SECRET_ACCESS_KEY
echo
export RCLONE_S3_ACCESS_KEY_ID RCLONE_S3_SECRET_ACCESS_KEY
export RCLONE_S3_PROVIDER=Minio
export RCLONE_S3_ENDPOINT=http://127.0.0.1:9000
```

I entered the same credentials used to start MinIO. The password is hidden while typing, and no credentials are saved in the script or README.

```bash
rclone --config /dev/null mkdir :s3:testpress-lab
rclone --config /dev/null lsd :s3:
```

mkdir creates the bucket, and lsd lists buckets. :s3: creates a connection on the fly, using the settings above. --config /dev/null makes rclone use an empty configuration instead of a saved file.

Configuration-free means no persistent configuration file. The connection still needs an endpoint and credentials.

### Upload, list, and download

```bash
rclone --config /dev/null copy \
  02-rclone/data/source :s3:testpress-lab --progress

rclone --config /dev/null ls :s3:testpress-lab
```

This uploaded the local files, including nested paths. Listing showed the objects in the bucket.

```bash
rclone --config /dev/null copy \
  :s3:testpress-lab 02-rclone/data/downloaded --progress

rclone check 02-rclone/data/source 02-rclone/data/downloaded
```

Download is just copy in the reverse direction. There is no separate download command: source comes first, destination comes second. I downloaded into a new folder and checked it against the original files; the round trip worked.

### Copy between buckets

These are the commands for copying into a second bucket:

```bash
rclone --config /dev/null mkdir :s3:testpress-backup
rclone --config /dev/null copy \
  :s3:testpress-lab :s3:testpress-backup --progress
rclone --config /dev/null ls :s3:testpress-backup
```

The same copy command works here too. Both locations are buckets, and the source bucket is kept. I have not recorded a separate result for this step yet.

### Delete one object

I used a disposable file so the other test data stayed untouched:

```bash
echo "Delete test" > /tmp/rclone-delete-test.txt
rclone --config /dev/null copyto \
  /tmp/rclone-delete-test.txt :s3:testpress-lab/delete-test.txt

rclone --config /dev/null deletefile \
  :s3:testpress-lab/delete-test.txt --dry-run

rclone --config /dev/null deletefile \
  :s3:testpress-lab/delete-test.txt
```

copyto lets me specify the exact object name. deletefile removes that one object. As with local sync, dry run previews the action before applying it.

### Large upload and interruption

I created a larger test file:

```bash
dd if=/dev/urandom of=02-rclone/data/source/large-1gb.bin \
  bs=1M count=1024 status=progress
```

This is 1 GiB, which also exceeds the exercise's 1 GB requirement. Then I uploaded with limits and retries:

```bash
rclone --config /dev/null copy \
  02-rclone/data/source :s3:testpress-lab \
  --transfers 2 \
  --bwlimit 20M \
  --retries 3 \
  --low-level-retries 5 \
  --progress
```

- --transfers 2 allows two files to transfer at once, not two chunks of one file.
- --bwlimit 20M limits total bandwidth to about 20 MiB/s.
- --retries 3 sets the overall attempt count.
- --low-level-retries 5 controls retries of individual failed operations.
- --progress shows bytes, speed, elapsed time, and estimated time remaining.

I pressed Ctrl+C at about 98 MiB. When I ran the same command again, the existing unchanged files were skipped. The second run showed about 808 MiB transferred in 43 seconds, consistent with uploading the large file again under the bandwidth limit.

The progress seemed to jump, but that alone does not mean it resumed. Restarting the command is different from retrying an operation within the same running process. This experiment tested interruption and restart; it did not prove automatic recovery from a network failure.

### Verify uploaded contents

```bash
rclone --config /dev/null check \
  02-rclone/data/source :s3:testpress-lab \
  --one-way --download
```

--one-way ignores objects found only in the bucket. --download reads the remote data for comparison instead of relying on a shared checksum, which is useful for multipart S3 uploads. It does not save another local copy or change the objects. It still reads the full data, so checking large files takes time.

### Pass settings directly to a command

I also tried provider and endpoint flags instead of exporting those settings:

```bash
rclone --config /dev/null \
  --s3-provider Minio \
  --s3-endpoint http://127.0.0.1:9000 \
  lsd :s3:
```

The credentials still come from the exported environment variables. This initially returned 403 AccessDenied. After entering and exporting the credentials again in that terminal, it worked.

Exported variables belong to that shell and its child processes. A new terminal does not automatically inherit exports made in another terminal. Endpoint flags tell rclone where to connect; they do not authenticate it.

### Summary

- Upload, download, and bucket-to-bucket transfer all use copy; the direction changes.
- --config /dev/null and :s3: let the command run without a saved remote.
- For another endpoint, pass its URL and matching credentials. I tested one local endpoint so far.
- For production, I would inject short-lived credentials from a secret manager or workload identity, rather than put secrets in command history, scripts, or Git. Local root credentials are only for this lab.
- PDF samples, changed-content sync, automatic retry failure testing, and additional credentials/endpoints remain separate follow-up experiments.

## Transfer script

I put the common command in transfer.sh. It takes the operation, source, and destination:

```bash
bash 02-rclone/transfer.sh copy 02-rclone/data/source :s3:testpress-lab
bash 02-rclone/transfer.sh sync 02-rclone/data/source 02-rclone/data/destination
```

Export the S3 variables from the section above before using an S3 destination. The script uses no saved rclone.conf, shows progress, and appends activity and errors to 02-rclone/logs/transfer.log. A failed rclone command makes the script return its failure exit code; check it immediately with `echo $?`.

Sync deletes destination-only files. Preview the same source and destination with `rclone --config /dev/null sync SOURCE DESTINATION --dry-run` before running the script with sync.
