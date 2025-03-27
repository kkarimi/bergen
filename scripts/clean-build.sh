#!/bin/bash

# Script to perform a completely clean build from scratch
# This helps resolve build errors that occur due to cached or corrupted files

set -e # Exit on error

echo "🧹 Performing a completely clean build from scratch..."

# Step 1: Remove build artifacts
echo "🗑️ Removing build artifacts..."
rm -rf macos/build
rm -rf macos/Pods
rm -f macos/Podfile.lock
rm -rf node_modules
rm -f yarn.lock
rm -f bergen.app
rm -f *-macos-v*.zip

# Step 2: Clear React Native cache
echo "🧹 Clearing React Native Metro bundler cache..."
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/react-*
rm -rf $TMPDIR/haste-*

# Step 3: Remove Xcode derived data (optional, uncomment if needed)
echo "🧹 Removing Xcode derived data related to Bergen..."
rm -rf ~/Library/Developer/Xcode/DerivedData/bergen-*

# Step 4: Reinstall dependencies
echo "📦 Reinstalling dependencies..."
yarn install

# Step 5: Reinstall pods
echo "📦 Reinstalling pod dependencies..."
cd macos && pod install && cd ..

# Step 6: Build the app with correct architecture flag
echo "🏗️ Building the app (arch-specific)..."

# Determine system architecture
if [ "$(uname -m)" = "arm64" ]; then
    # For Apple Silicon (M1/M2)
    ARCH="arm64"
else
    # For Intel Macs
    ARCH="x86_64"
fi

echo "🖥️ Building for architecture: $ARCH"
cd macos && xcodebuild -workspace bergen.xcworkspace -scheme "bergen-macOS" -configuration Release -arch $ARCH clean build && cd ..

# Step 7: Find the built app
echo "🔍 Searching for the built app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/bergen-* -name "bergen.app" 2>/dev/null | head -n 1)

if [ -n "$APP_PATH" ]; then
    echo "✅ Build completed successfully!"
    echo "📍 The app can be found at: $APP_PATH"
    
    # Create a symlink in the project root
    ln -sf "$APP_PATH" ./bergen.app
    echo "🔗 Symlink created at ./bergen.app"
    
    # Create distribution zip
    echo "📦 Creating distribution zip..."
    VERSION=$(node -p "require('../package.json').version")
    ZIP_NAME="bergen-macos-v${VERSION}.zip"
    
    # Use nuclear option for signing
    echo "🔐 Running nuclear signing fix..."
    ./nuke-and-rebuild.sh
    
    echo "✅ Clean build and signing completed successfully!"
else
    echo "❌ Build failed or app not found."
    exit 1
fi