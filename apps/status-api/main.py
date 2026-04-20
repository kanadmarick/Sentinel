import os
import re
import threading

import uvicorn
import zmq
from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, Gauge, generate_latest

app = FastAPI(title="Aether Brain")

# Prometheus gauges updated from incoming ZMQ telemetry.
CPU_GAUGE = Gauge("sentinel_cpu_load", "Real-time CPU load from Sentinel Watchdog", ["node_id"])
MEM_GAUGE = Gauge("sentinel_mem_usage", "Real-time RAM usage from Sentinel Watchdog", ["node_id"])

ZMQ_ADDR = os.getenv("SENTINEL_ZMQ_ADDR", "tcp://127.0.0.1:5555")
latest_briefing = {"data": "Awaiting first heartbeat..."}


def parse_metrics_from_md(md_text):
    """Extract CPU and memory percentages from markdown text."""
    try:
        matches = re.findall(r"(\d+\.?\d*)%", md_text)
        if len(matches) >= 2:
            cpu_val = float(matches[0])
            mem_val = float(matches[1])
            return cpu_val, mem_val
    except Exception as error:
        print(f"Parsing error: {error}")
    return None, None


def zmq_listener():
    ctx = zmq.Context()
    sub = ctx.socket(zmq.SUB)
    sub.connect(ZMQ_ADDR)
    sub.subscribe("")

    print(f"Bridge Thread: Listening to Nerves at {ZMQ_ADDR}")

    while True:
        message = sub.recv_string()
        latest_briefing["data"] = message

        # Bridge ZMQ telemetry into Prometheus metrics.
        cpu, mem = parse_metrics_from_md(message)
        if cpu is not None and mem is not None:
            CPU_GAUGE.labels(node_id="legion-5").set(cpu)
            MEM_GAUGE.labels(node_id="legion-5").set(mem)


@app.on_event("startup")
def startup_event():
    threading.Thread(target=zmq_listener, daemon=True).start()


@app.get("/status")
async def get_status():
    return {"briefing": latest_briefing["data"]}


@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
