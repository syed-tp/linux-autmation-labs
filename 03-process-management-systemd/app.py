"""Testpress cricket heartbeat worker. Standard library only."""
import math
import os
import random
import signal
import sys
import threading


def main():
    try:
        interval = float(os.getenv("HEARTBEAT_SECONDS", "5"))
        crash_after = int(os.getenv("CRASH_AFTER", "0"))
        if not math.isfinite(interval) or interval <= 0 or crash_after < 0:
            raise ValueError("heartbeat must be positive and crash count nonnegative")
    except ValueError as error:
        print(f"Invalid configuration: {error}", flush=True)
        return 2

    stopped = threading.Event()

    def handle_shutdown(signum, frame):
        # Leave printing and cleanup to the main loop.
        stopped.set()

    signal.signal(signal.SIGTERM, handle_shutdown)
    signal.signal(signal.SIGINT, handle_shutdown)
    batting = os.getenv("BATTING_TEAM", "DevOps XI")
    bowling = os.getenv("BOWLING_TEAM", "Backend XI")
    print("=== TESTPRESS TEST MATCH ===", flush=True)
    print(f"{batting} vs {bowling} | PID: {os.getpid()}", flush=True)
    print(f"Heartbeat: {interval}s | Crash after: {crash_after or 'disabled'}", flush=True)
    runs = wickets = balls = heartbeats = innings = 0
    descriptions = {0: "Dot ball.", 1: "Single.", 2: "Two runs.",
                    3: "Three runs!", 4: "FOUR!", 6: "SIX! Into the stands!",
                    "W": "WICKET! The pipeline is broken!"}

    while not stopped.wait(interval):
        outcome = random.choice([0, 1, 2, 3, 4, 6, "W"])
        balls += 1
        heartbeats += 1
        if outcome == "W":
            wickets += 1
        else:
            runs += outcome
        print(f"Heartbeat {heartbeats} | PID {os.getpid()} | "
              f"{balls // 6}.{balls % 6} overs | {descriptions[outcome]} "
              f"| {batting}: {runs}/{wickets}", flush=True)
        if crash_after and heartbeats >= crash_after:
            print("Floodlight failure! Simulated crash; exit status 1.", flush=True)
            return 1
        if wickets == 10:
            innings += 1
            print(f"ALL OUT! Innings {innings}: {runs}/10. Starting a new innings.", flush=True)
            runs = wickets = balls = 0

    print("Rain stops play! Shutdown requested by SIGTERM or SIGINT.", flush=True)
    print(f"Final score: {batting} {runs}/{wickets}", flush=True)
    print("Testpress commentary signing off. Cleanup complete.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
