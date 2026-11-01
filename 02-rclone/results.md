# Results and learnings

## Local operations

- Listing showed hello.txt as 21 bytes and notes/lesson.txt as 16 bytes. The newline written by echo counts too.
- Copy kept destination-only extra.txt. Copy does not make the two locations identical by deleting extras.
- The first check reported 0 differences and 2 matching files.
- Sync dry run showed extra.txt would be deleted. Its `Deleted: 1` summary was a preview; the file stayed until actual sync ran.
- Move transferred the selected file and removed it from source.
- One-way check ignores destination extras, but every source file must still exist and match.
- The missing rclone.conf notice was harmless for local operations.

## Working with S3

MinIO ran directly on the local machine using setup.sh. Its readiness check succeeded. No paid storage or Docker was needed.

Bucket creation, listing, upload, and download worked with an empty rclone configuration. The downloaded files were checked against the originals successfully.

Download is just copy the other way around. Upload, download, and bucket-to-bucket copy all use the same source/destination pattern.

A bucket contains objects. A name such as notes/lesson.txt is an object key, even though it looks like a filesystem path.

## Interrupted upload

I interrupted the 1 GiB upload at about 98 MiB. On the next run, three existing files were checked and skipped. The large file showed about 808 MiB transferred after 43 seconds, at roughly 19 MiB/s under the 20 MiB/s limit.

After stopping the upload with Ctrl+C and running the command again, rclone skipped the completed files and started the interrupted large-file upload from the beginning.

## Credentials and configuration

The on-the-fly listing initially returned 403 AccessDenied. Exporting the correct credentials again in that terminal fixed it.

Environment variables belong to the shell and its child processes. Exports in one terminal are not automatically available in another. Provider and endpoint flags identify the storage service; credentials authenticate the request.

Configuration-free means no saved rclone.conf, not no configuration. For production, I would inject short-lived credentials from a secret manager or workload identity rather than store them in scripts, command history, or Git. MinIO root credentials were used only for this local lab.

## Checks still to record

- A separate bucket-to-bucket result.
- PDF sample files and sync with changed file contents.
- Automatic retry behavior during a network failure.
- Operations with different credentials and endpoints.
- Functional tests and failure exit codes for transfer.sh; Bash syntax was checked.

Commands for the experiments are in [commands.md](commands.md).
