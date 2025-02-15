#!/usr/bin/env python3
import os
import sys
import time
from datetime import datetime

def main():
    log_file = sys.argv[1] if len(sys.argv) > 1 else "/tmp/app.log"
    index = 0
    regular_rate = int(os.environ.get('REGULAR_RATE', 70))  # kb per second outside of burst
    burst_rate = int(os.environ.get('BURST_RATE', 250))  # kb per second during burst
    burst_interval = int(os.environ.get('BURST_INTERVAL', 30))  # Time between bursts
    burst_duration = int(os.environ.get('BURST_DURATION', 2))  # How long to send rapid logs for
    last_burst = time.time() - burst_interval  # Start ready for a burst
    burst_end = 0

    # Calculate bytes per log line (including timestamp and formatting)
    log_entry = "X" * 1000
    sample_line = f"{datetime.now().isoformat(timespec='seconds')} [BURST-00000] {log_entry}\n"
    bytes_per_line = len(sample_line.encode('utf-8'))

    # Convert KB rates to number of lines
    regular_lines = int((regular_rate * 1024) / bytes_per_line)
    burst_lines = int((burst_rate * 1024) / bytes_per_line)

    try:
        while True:
            current_time = time.time()
            timestamp = datetime.now().isoformat(timespec='seconds')

            # Start a new burst if enough time has passed since the last one
            if current_time - last_burst >= burst_interval and current_time > burst_end:
                last_burst = current_time
                burst_end = current_time + burst_duration
                print(f"Starting burst at {timestamp}: writing {burst_lines} lines/s ({burst_rate}KB/s) for {burst_duration}s")

            # Determine if we're in a burst period
            in_burst = current_time <= burst_end
            num_logs = burst_lines if in_burst else regular_lines

            if in_burst:
                print(f"In burst: {num_logs} lines/s")
            else:
                print(f"Regular rate: {num_logs} lines/s")

            for _ in range(num_logs):
                log_entry = "X" * 1000
                log_line = f"{timestamp} [BURST-{index:05d}] {log_entry}\n"
                with open(log_file, 'a') as f:
                    f.write(log_line)
                print(log_line, end='')
                index += 1

            print(f"Wrote {num_logs} lines at {timestamp}")

            time.sleep(1)

    except KeyboardInterrupt:
        sys.exit(0)

if __name__ == "__main__":
    main()
