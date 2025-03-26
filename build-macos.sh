#!/bin/bash

# Exit on error
set -e

echo "🏗 Building React Native macOS app for production..."

# Clean the build directory
echo "🧹 Cleaning build directory..."
rm -rf macos/build

# Install dependencies
echo "📦 Installing dependencies..."
yarn install

# Generate the necessary codegen files and workspace
echo "🔧 Setting up Xcode workspace..."
cd macos
rm -rf Pods
rm -f Podfile.lock
pod install
echo "✅ Workspace setup complete"

# Build the React Native macOS app
echo "🚀 Building macOS app..."
xcodebuild -workspace bergen.xcworkspace -scheme "bergen-macOS" -configuration Release clean build

# Verify build output exists
echo "🔍 Searching for the built app..."

# Check in the default Xcode build locations
DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA_DIR" -name "bergen.app" 2>/dev/null | head -n 1)

if [ -n "$APP_PATH" ]; then
    echo "✅ Build completed successfully!"
    echo "📍 The app can be found at: $APP_PATH"
    
    # Create a symlink in the project root for easy access
    cd ..
    ln -sf "$APP_PATH" ./bergen.app
    echo "🔗 Symlink created at ./bergen.app for easy access"

    # Install to Applications directory
    echo "📲 Installing to Applications directory..."
    if [ -d "/Applications/bergen.app" ]; then
        echo "🗑️ Removing existing installation..."
        rm -rf "/Applications/bergen.app"
    fi
    echo "📋 Copying app to Applications directory..."
    cp -R bergen.app /Applications/
    echo "✅ App installed to /Applications/bergen.app"

    # Create a zip file for distribution
    echo "📦 Creating zip file for distribution..."
    VERSION=$(node -p "require('./package.json').version")
    ZIP_NAME="bergen-macos-v${VERSION}.zip"
    ditto -c -k --keepParent bergen.app "$ZIP_NAME"
    echo "✅ Zip file created at $ZIP_NAME"
else
    echo "❌ Build output not found"
    echo "🔍 Searching for the app in all possible locations:"
    find "$DERIVED_DATA_DIR" -name "bergen.app" 2>/dev/null
    exit 1
fi 