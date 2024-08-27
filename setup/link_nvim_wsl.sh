#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
RESET='\033[0m'

# Get the value of %LOCALAPPDATA% using cmd.exe
LOCALAPPDATA=$(cmd.exe /c echo %LOCALAPPDATA%)

# Convert Windows path to WSL path
WSL_PATH=$(echo "$LOCALAPPDATA" | sed 's/\\/\//g' | sed 's/^C:/\/mnt\/c/' | tr -d '\r' )

# Define the source and target paths
SOURCE_PATH="${WSL_PATH}/nvim"
TARGET_PATH="$HOME/.config/nvim"

# Check if the symbolic link already exists
if [ -e "$TARGET_PATH" ]; then
    echo -e "${RED}Error:${RESET} Symbolic link already exists at $TARGET_PATH. No action taken."
else
    # Check if the source path exists
    if [ -d "$SOURCE_PATH" ]; then
        # Create a symbolic link from the source to the target
        ln -s "$SOURCE_PATH" "$TARGET_PATH"
        echo "Symbolic link created successfully."
    else
        echo -e "${RED}Error:${RESET} Source path does not exist ($SOURCE_PATH). No action taken."
    fi
fi
