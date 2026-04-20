from datetime import datetime, timezone # Import timezone for handling timestamps in UTC
from typing import Optional # Import Optional for optional fields in the Heartbeat model

from fastapi import FastAPI, Request # Import FastAPI for creating the API and Request for accessing request information
from pydantic import BaseModel, Field # Import BaseModel and Field from Pydantic for defining the data model and field validation

# Create the FastAPI application instance with metadata
app = FastAPI(
    title="Sentinel Ingestion API",
    description="API for ingesting data into Sentinel",
    version="1.0.0",
)

# Define the data model for the heartbeat using Pydantic
class Heartbeat(BaseModel):
    server_name: str = Field(..., examples=["Legion-Node-01"])# Server name with an example value
    cpu_load: float = Field(..., ge=0, le=100, examples=[75.5])# CPU load percentage with validation to ensure it's between 0 and 100, and an example value
    ram_usage: float = Field(..., ge=0, le=100, examples=[60.2])# RAM usage percentage with validation to ensure it's between 0 and 100, and an example value
    status: Optional[str] = "HEALTHY"# Optional status field with a default value of "HEALTHY"
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),# Timestamp field with a default value of the current time in UTC
        examples=["2024-06-01T12:00:00Z"],# Example value for the timestamp field in ISO 8601 format
    )


@app.get("/status")
async def get_status():
    """Health check endpoint for smoke tests."""
    return {"status": "operational", "service": "ingestion"}


@app.post("/ingest/pulse")# Define a POST endpoint for ingesting heartbeat data
async def ingest_pulse(heartbeat: Heartbeat, request: Request): # Define the endpoint function that takes a Heartbeat object and the Request object
    client_ip = request.client.host if request.client else "unknown" # Get the client's IP address from the request, or set it to "unknown" if not available
    arrival_time = datetime.now(timezone.utc) # Get the current time in UTC to calculate latencys
    latency_ms = (arrival_time - heartbeat.timestamp).total_seconds() * 1000 # Calculate the latency in milliseconds by finding the difference between the arrival time and the heartbeat timestamp
# Log the received heartbeat data along with the client's IP address and latency
    return {
        "status": "acknowledged",
        "latency": latency_ms,
        "source_ip": client_ip,
        "processed_at": arrival_time,
    }

# Run the application using Uvicorn when the script is executed directly
if __name__ == "__main__":
    import uvicorn
# Start the Uvicorn server with the application, listening on all interfaces at port 8000, and enable auto-reload for development
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)