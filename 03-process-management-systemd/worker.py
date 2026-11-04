import os
import random
import signal
import time

runs = 0
wickets = 0
balls = 0
running = True


def handle_shutdown(signum, frame):
    global running
    print(
        f"\nRain stops play! Received {signal.Signals(signum).name}.",
        flush=True,
    )
    running = False


signal.signal(signal.SIGTERM, handle_shutdown)
signal.signal(signal.SIGINT, handle_shutdown)

print("=" * 55, flush=True)
print("🏏 TESTPRESS TEST MATCH", flush=True)
print("DevOps XI vs Backend XI", flush=True)
print("DevOps XI won the toss and elected to bat.", flush=True)
print(f"Commentary worker PID: {os.getpid()}", flush=True)
print("=" * 55, flush=True)

commentaries = {
    0: "Dot ball. Solid defence!",
    1: "A quick single.",
    2: "Good running! Two runs.",
    3: "Into the gap! Three runs.",
    4: "FOUR! A beautiful cover drive!",
    6: "SIX! Deployed straight into the stands!",
    "W": "WICKET! Backend XI breaks the pipeline!",
}

while running and wickets < 10:
    time.sleep(3)

    if not running:
        break

    outcome = random.choice([0, 1, 2, 3, 4, 6, "W"])
    balls += 1

    if outcome == "W":
        wickets += 1
    else:
        runs += outcome

    overs = f"{balls // 6}.{balls % 6}"

    print(
        f"[{overs} overs] {commentaries[outcome]} "
        f"| DevOps XI: {runs}/{wickets}",
        flush=True,
    )

print("\n" + "=" * 55, flush=True)

if wickets == 10:
    print("ALL OUT! Backend XI closes the innings.", flush=True)
else:
    print("Play suspended. Players leave the field.", flush=True)

print(
    f"Final score: DevOps XI {runs}/{wickets} "
    f"in {balls // 6}.{balls % 6} overs",
    flush=True,
)
print("Testpress commentary signing off.", flush=True)