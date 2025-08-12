# 🎬 FFmpeg Processing Service Dockerfile
FROM jrottenberg/ffmpeg:4.4-alpine

# Install Python for processing scripts
RUN apk add --no-cache python3 py3-pip

WORKDIR /app

# Copy processing scripts
COPY scripts/video_processor.py .

# Create directories
RUN mkdir -p /input /output /hls

# Default command
CMD ["python3", "video_processor.py"]
