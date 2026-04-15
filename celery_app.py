import os
from celery import Celery
from dotenv import load_dotenv

load_dotenv()

# Initialize Celery
app = Celery('sentinel',
             broker=f"redis://localhost:6379/0",
             backend=f"redis://localhost:6379/0")

# Optional: Configuration for reliability
app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='Asia/Kolkata',
    enable_utc=True,
)

@app.task
def process_telemetry(data):
    # This is where the Brain 'reasons' over the data
    print(f"🧠 Brain Processing Data: {data}")
    return "Success"