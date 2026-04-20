import os
from celery import Celery
from dotenv import load_dotenv

load_dotenv()

# Get Redis connection details from environment variables, with fallbacks for local dev
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = os.getenv('REDIS_PORT', '6379')

# Initialize Celery
app = Celery('sentinel',
             broker=f"redis://{REDIS_HOST}:{REDIS_PORT}/0",
             backend=f"redis://{REDIS_HOST}:{REDIS_PORT}/0")

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