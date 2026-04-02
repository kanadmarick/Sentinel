#-- Stage 1: Build Stage
# This stage is responsible for installing all the dependencies and preparing the application for production.
# Use a lightweight Python image as the base for the build stage 
FROM python:3.12-slim AS builder 
WORKDIR /app # Set the working directory inside the container
# Install build dependencies and clean up apt cache to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/* # Install build tools and clean up apt cache
# Copy the requirements file to the working directory
COPY requirements.txt . 
RUN pip wheel --no-cache-dir --wheel-dir=/app/wheels -r requirements.txt # Build the wheel files for the dependencies


#--Stage 2: Final Runtime Stage
# This stage is responsible for creating the final image that will be used in production.
# Use a lightweight Python image as the base for the final stage
FROM python:3.12-slim
WORKDIR /app # Set the working directory inside the container
# Install runtime dependencies and clean up apt cache to reduce image size
RUN apt-get update && apt-get install -y libpq-dev && rm -rf /var/lib/apt/lists/* # Install runtime dependencies and clean up apt cache
# Copy the built wheel files from the builder stage and install them
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/* # Install the dependencies from the wheel files
# Copy the application code to the working directory
COPY . . 
# Expose the port that the application will run on
EXPOSE 8000