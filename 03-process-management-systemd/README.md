# Linux Process Management & systemd — Exercise 03

A cricket commentary worker demonstrates Linux signals, service recovery and resource limits.
The final app runs continuously, emits a heartbeat every five seconds, starts another innings
after all out, and exits cleanly on SIGTERM or SIGINT. Scores are in memory and reset on restart.

## Files

- `app.py`: final worker; `worker.py`: original manually tested prototype.
- `cricket-pitch.service.template`: reference for the dependency experiment in the Extra section; includes success and failure commands.
- `worker.env.example`: configuration example.
- `setup.sh`: reproducible system service installation.
- `cricket-worker.service.template`: service settings; setup.sh fills in the app directory and installs the service.
- [experiments.md](experiments.md): illustrated walkthrough, commands, observations, learnings, dependencies and evidence checklist.
- `evidence/`: original Linux screenshots, stored once and embedded in the walkthrough.

## Requirements and setup

Use local Linux or a Linux VM with systemd and Python 3. WSL is supported when PID 1 is
systemd. Administrative access is needed to install the system unit and create a dedicated
account; the Python application itself never runs as root.

From this directory:

```bash
ps -p 1 -o comm=
python3 app.py
# Ctrl+C exits cleanly.
sudo bash ./setup.sh
# Stop the earlier user-service experiment to avoid duplicate workers:
systemctl --user stop cricket-worker
sudo systemctl enable --now cricket-worker
sudo systemctl status cricket-worker --no-pager
sudo journalctl -u cricket-worker -f
```

The installer creates the service from its template and copies code to the deployment location `/opt/cricket-worker`.
This path is independent of the clone location. The service runs as the dedicated
`cricket-worker` system account, whose login shell is disabled. Files are root-owned
and readable by the service account. Re-running setup updates code and the unit but preserves
`/etc/cricket-worker.env`; restart the service to run updated code.
Old user-service overrides do not affect the final system service.

## Configuration

Edit `sudo nano /etc/cricket-worker.env`, then run
`sudo systemctl restart cricket-worker`. This file uses systemd environment-file syntax,
not a shell script. No secrets are needed.

| Variable | Default | Meaning |
|---|---|---|
| HEARTBEAT_SECONDS | 5 | Positive interval between balls/heartbeats |
| BATTING_TEAM | DevOps XI | Batting team name |
| BOWLING_TEAM | Backend XI | Bowling team name |
| CRASH_AFTER | 0 | Heartbeat count at which to exit 1; 0 disables |

For a quick manual crash demonstration:
`HEARTBEAT_SECONDS=0.1 CRASH_AFTER=1 python3 app.py`.
Check `echo $?` immediately afterward: expected 1.

## Service behaviour

`Restart=on-failure` restarts after an exit status 1 or SIGKILL, waiting three seconds.
Our SIGTERM handler exits 0 and stays stopped. An explicit `systemctl stop` also stays
stopped. Rate limiting permits three starts in a rolling 30-second interval before rejecting
further starts. Recover by fixing the cause, running `sudo systemctl reset-failed cricket-worker`,
then starting it. Limits apply to the service cgroup: 20% of one CPU, 50 MiB memory and no swap.
CPU demand is throttled; excessive memory can trigger an OOM kill.
`enable` configures future boot startup; `start` runs now; `enable --now` does both.

## Reboot verification

Finish and restore crash-test configuration before rebooting.
On a normal Linux machine use `sudo reboot` when ready.
For WSL, save other work, then run `wsl.exe --terminate Ubuntu` from PowerShell and reopen
Ubuntu; this stops all processes in that distribution. It does not reboot Windows.
After Linux starts, capture:

```bash
uptime -s
cat /proc/sys/kernel/random/boot_id
sudo systemctl is-enabled cricket-worker
sudo systemctl status cricket-worker --no-pager
sudo journalctl -b -u cricket-worker --no-pager
```

For WSL, kernel boot time/ID can be shared with other distributions; distribution restart is
not necessarily a fresh kernel boot. If the evaluator requires a full server reboot, use a VM
or restart all WSL with `wsl.exe --shutdown` after saving all WSL work.

## Diagnostics and cleanup

```bash
sudo systemctl cat cricket-worker
sudo systemctl show cricket-worker -p MainPID -p Result -p NRestarts
sudo systemd-analyze verify /etc/systemd/system/cricket-worker.service
systemd-analyze time
sudo systemctl disable --now cricket-worker
```

See experiments.md for destructive test commands, restoration steps and missing evidence.
Screenshots show the earlier user service with `--user`; the final setup
uses the same unit name under the system manager, with commands without `--user`.

References: [systemd.service](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html),
[resource controls](https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html).
