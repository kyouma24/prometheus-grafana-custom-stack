#!/bin/bash

# Define container names
CONTAINERS=("my-org" "asciidoctor") 

# Function to check logs and restart container if needed
check_and_restart() {
  local CONTAINER_NAME=$1

  # Get the container log file path
  LOG_FILE=$(docker inspect --format='{{.LogPath}}' "$CONTAINER_NAME")

  # Ensure log file exists before proceeding
  if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
    echo "Log file for container $CONTAINER_NAME not found. Skipping..."
    return
  fi

  # Check if the log file was modified in the last 10 minutes
  if ! find "$LOG_FILE" -mmin -10 | grep -q .; then
    echo "No logs detected in the last 10 minutes. Restarting container: $CONTAINER_NAME"

    # Change to the directory before restarting the container
    cd /home/ubuntu/grafana-pro || exit

    # Restart the container
    docker compose restart "$CONTAINER_NAME"
  else
    echo "Logs detected for $CONTAINER_NAME in the last 10 minutes. No action needed."
  fi
}

# Loop through both containers
for CONTAINER in "${CONTAINERS[@]}"; do
  check_and_restart "$CONTAINER"
done

