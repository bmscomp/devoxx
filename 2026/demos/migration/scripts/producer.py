#!/usr/bin/env python3
"""Auto-publish timestamped messages to stdout for piping into kafka-console-producer."""
import signal, sys, time, datetime

def graceful_exit(*_):
    print("\n\033[0;32m✓ Producer stopped gracefully.\033[0m", file=sys.stderr)
    sys.exit(0)

signal.signal(signal.SIGINT, graceful_exit)
signal.signal(signal.SIGTERM, graceful_exit)

i = 1
while True:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    print(f"devoxx-{i}-{ts}", flush=True)
    i += 1
    time.sleep(1)
