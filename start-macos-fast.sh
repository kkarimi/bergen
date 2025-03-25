#!/bin/bash

# Start the Metro bundler if it's not already running
if ! pgrep -f "react-native start" > /dev/null; then
    yarn start &
    sleep 5  # Wait for Metro to start
fi

# Check if we need to build
if [ ! -d "macos/DerivedData/bergen/Build/Products/Debug/bergen.app" ]; then
    echo "No debug build found. Building for the first time..."
    yarn macos
else
    # Open the existing build
    open macos/DerivedData/bergen/Build/Products/Debug/bergen.app
fi 