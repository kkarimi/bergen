#!/bin/bash

# Exit on error
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "🔑 Loading environment variables from .env file..."
    source .env
fi

echo "🚀 Preparing to submit Bergen app to the Mac App Store..."

# Check for required variables
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
    echo "⚠️ APPLE_ID or APPLE_ID_PASSWORD is not set in your .env file"
    echo "These are required for App Store submission."
    echo "Please update your .env file with:"
    echo "APPLE_ID=\"your.apple.id@example.com\""
    echo "APPLE_ID_PASSWORD=\"your-app-specific-password\""
    exit 1
fi

# Check if a built PKG file already exists
VERSION=$(node -p "require('../package.json').version")
PKG_NAME="bergen-appstore-v${VERSION}.pkg"

if [ ! -f "$PKG_NAME" ]; then
    echo "❌ PKG file not found: $PKG_NAME"
    echo "You need to build the app for App Store submission first:"
    echo "./app-store-build.sh"
    
    # Ask if user wants to build now
    read -p "Would you like to build the app now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./app-store-build.sh
        
        # Check again if the PKG was created
        if [ ! -f "$PKG_NAME" ]; then
            echo "❌ Build failed or did not produce a PKG file."
            exit 1
        fi
    else
        exit 1
    fi
fi

echo "📦 Found PKG file: $PKG_NAME"

# Validate the PKG file
echo "🔍 Validating the PKG file..."
xcrun altool --validate-app -f "$PKG_NAME" -t macos -u "$APPLE_ID" -p "$APPLE_ID_PASSWORD"

# Ask for confirmation before submission
read -p "Ready to submit to the App Store. Proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Submission canceled."
    exit 0
fi

# Submit to App Store
echo "🚀 Submitting to Mac App Store..."
xcrun altool --upload-app -f "$PKG_NAME" -t macos -u "$APPLE_ID" -p "$APPLE_ID_PASSWORD"

echo "✅ Submission completed!"
echo "🔍 Check App Store Connect for the status of your submission:"
echo "https://appstoreconnect.apple.com/apps"
echo ""
echo "⏳ It may take some time for your app to appear in App Store Connect."
echo "Once it appears, you'll need to complete all required metadata before"
echo "it can be reviewed by Apple."