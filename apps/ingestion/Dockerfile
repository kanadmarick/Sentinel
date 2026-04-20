FROM python:3.12-slim
# Install system dependencies (needed for some ZMQ/Redis builds)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app

COPY requirements.txt .
# Install the dependencies from the requirements file
RUN pip install --no-cache-dir -r requirements.txt
# Copy the application code to the working directory
COPY main.py .
COPY celery_app.py .

EXPOSE 8000
# Start the Uvicorn server with the application, listening on all interfaces at port 8000make build
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]