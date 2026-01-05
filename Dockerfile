# Mock Integration Server for local upskilling
FROM python:3.11-slim

WORKDIR /app

# Copy employee folder (just to simulate package deployment)
COPY ./employee /app/employee

# Expose IS-like port
EXPOSE 5555

# Simple HTTP server to simulate IS being UP
CMD ["python3", "-m", "http.server", "5555"]
