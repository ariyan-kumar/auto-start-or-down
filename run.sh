#!/bin/bash

# Define server JAR file
JAR_PATH="./server.jar"

# Plugin download URLs
NO_PLAYER_SHUTDOWN_URL="https://github.com/Mindgamesnl/NoPlayerShutdown/releases/latest/download/NoPlayerShutdown.jar"
SPARK_URL="https://ci.lucko.me/job/spark/lastSuccessfulBuild/artifact/spark-bukkit/build/libs/spark.jar"

# Plugin directory
PLUGIN_DIR="plugins"
mkdir -p "$PLUGIN_DIR"

# Server logs for detecting player attempts
LOG_FILE="logs/latest.log"

# Function to download a plugin if missing
download_plugin() {
    local url=$1
    local file_path=$2
    if [ ! -f "$file_path" ]; then
        echo "Downloading $(basename "$file_path")..."
        curl -L "$url" -o "$file_path"
    else
        echo "$(basename "$file_path") already exists."
    fi
}

# Download NoPlayerShutdown & Spark if missing
download_plugin "$NO_PLAYER_SHUTDOWN_URL" "$PLUGIN_DIR/NoPlayerShutdown.jar"
download_plugin "$SPARK_URL" "$PLUGIN_DIR/spark.jar"

# Ensure NoPlayerShutdown config is set correctly
PLUGIN_CONFIG="$PLUGIN_DIR/NoPlayerShutdown/config.yml"
echo "Configuring NoPlayerShutdown plugin to prevent abuse..."
if [ -f "$PLUGIN_CONFIG" ]; then
    sed -i 's/auto-shutdown-timeout: .*/auto-shutdown-timeout: 14400/' "$PLUGIN_CONFIG"  # 4H (14400s)
    sed -i 's/allow-bypass: .*/allow-bypass: false/' "$PLUGIN_CONFIG"
else
    echo "Warning: NoPlayerShutdown config.yml not found! It will be generated on first run."
fi

# Main loop to start/restart the server when a player joins
while true; do
    echo "Starting Minecraft server..."
    java -jar "$JAR_PATH" nogui

    echo "Server has stopped. Waiting for player join attempt..."

    # Wait for a player join attempt (monitor logs for connection attempts)
    while true; do
        sleep 10  # Check every 10 seconds

        # If a player tries to join, restart the server
        if grep -i "logged in" "$LOG_FILE" | tail -1; then
            echo "Player detected! Restarting server..."
            break
        fi
    done
done
