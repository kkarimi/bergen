#!/bin/bash

# Find the actual location of the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "bergen.app" 2>/dev/null | head -n 1)

# Start the Metro bundler if it's not already running
if ! pgrep -f "react-native start" > /dev/null; then
    echo "Starting Metro bundler with explicit host..."
    yarn start --host 127.0.0.1 &
    sleep 5  # Wait for Metro to start
fi

# Check if we need to build
if [ -z "$APP_PATH" ]; then
    echo "No debug build found. Building for the first time..."
    yarn macos
else
    echo "Opening existing build at: $APP_PATH"
    # Open the existing build
    open "$APP_PATH"
fi