#!/usr/bin/env bash

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

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
        echo -e "${CYAN}Downloading $(basename "$file_path")...${RESET}"
        curl -L "$url" -o "$file_path"
    else
        echo -e "${GREEN}$(basename "$file_path") already exists.${RESET}"
    fi
}

# Download NoPlayerShutdown & Spark if missing
download_plugin "$NO_PLAYER_SHUTDOWN_URL" "$PLUGIN_DIR/NoPlayerShutdown.jar"
download_plugin "$SPARK_URL" "$PLUGIN_DIR/spark.jar"

# Ensure NoPlayerShutdown config is set correctly
PLUGIN_CONFIG="$PLUGIN_DIR/NoPlayerShutdown/config.yml"
echo -e "${YELLOW}Configuring NoPlayerShutdown plugin to prevent abuse...${RESET}"
if [ -f "$PLUGIN_CONFIG" ]; then
    sed -i 's/auto-shutdown-timeout: .*/auto-shutdown-timeout: 14400/' "$PLUGIN_CONFIG"  # 4H (14400s)
    sed -i 's/allow-bypass: .*/allow-bypass: false/' "$PLUGIN_CONFIG"
else
    echo -e "${RED}Warning: NoPlayerShutdown config.yml not found! It will be generated on first run.${RESET}"
fi

# First-time startup
echo -e "${GREEN}Starting Minecraft server for the first time...${RESET}"
java -jar "$JAR_PATH" nogui

# Main loop: Wait for player join attempt to restart server
while true; do
    echo -e "${YELLOW}Server has stopped. Waiting for a player join attempt...${RESET}"

    # Wait for player join attempt (monitor logs for connection attempts)
    while true; do
        sleep 10  # Check every 10 seconds

        # If a player tries to join, restart the server
        if grep -i "logged in" "$LOG_FILE" | tail -1; then
            echo -e "${GREEN}Player detected! Restarting server...${RESET}"
            break
        fi
    done

    echo -e "${CYAN}Starting Minecraft server...${RESET}"
    java -jar "$JAR_PATH" nogui
done
