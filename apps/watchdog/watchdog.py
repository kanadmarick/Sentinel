import os
import time
from datetime import datetime

import psutil
import zmq

ZMQ_ADDR = os.getenv("SENTINEL_ZMQ", "tcp://127.0.0.1:5555") # ZMQ address for Sentinel communication
NODE_NAME = os.getenv("SENTINEL_NODE_NAME", "Legion-5")


def get_briefing():
    cpu = psutil.cpu_percent(interval=1) # Get CPU usage percentage
    mem = psutil.virtual_memory().percent # Get memory usage percentage
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    status = "CRITICAL" if cpu > 90 or mem > 90 else "OK" # Determine status based on thresholds
    return f"""
### Node: {NODE_NAME}
**Status:** {status}
**Time:** {timestamp}

| Metric | Value |
| :--- | ---: |
| CPU Load | {cpu}% |
| Memory Usage | {mem}% |
"""


def main():
    context = zmq.Context() # Create a ZMQ context
    socket = context.socket(zmq.PUB) # Create a PUB socket for sending messages to Sentinel
    socket.bind(ZMQ_ADDR) # Bind the socket to the specified address
    print(f"Watchdog started, sending updates to Sentinel at {ZMQ_ADDR}")

    try:
        while True:
            briefing = get_briefing() # Get the current system status briefing
            socket.send_string(briefing) # Send the briefing to Sentinel via ZMQ
            time.sleep(2) # Wait for 2 seconds before sending the next update
    except KeyboardInterrupt:
        print("Watchdog stopped by user.") # Log message indicating that the Watchdog has been stopped by the user
    finally:
        socket.close() # Close the ZMQ socket
        context.term()


if __name__ == "__main__":
    main()
