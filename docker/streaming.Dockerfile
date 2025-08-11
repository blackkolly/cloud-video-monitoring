# 🐳 Streaming Service Dockerfile
FROM python:3.9-slim

# Install system dependencies including FFmpeg
RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy streaming service
COPY src/streaming/ ./src/streaming/
COPY config/ ./config/

# Create necessary directories
RUN mkdir -p videos hls static processed

# Expose port
EXPOSE 8006

# Set Python path
ENV PYTHONPATH=/app

# Run streaming service
CMD ["python", "src/streaming/simple_video_streamer.py"]
