#!/bin/bash

# Exit on error
set -e

echo "🛠️ Super Fix Signing Script for macOS Apps 🛠️"
echo "This script will completely rebuild the app bundle to ensure proper signing"

# Ensure we have an app to fix
if [ ! -d "./bergen.app" ]; then
    echo "❌ Error: bergen.app not found in the current directory"
    exit 1
fi

# Create a new directory for our rebuilt app
TEMP_DIR="./temp_app_$(date +%s)"
mkdir -p "$TEMP_DIR"

echo "📦 Extracting app contents..."
# Extract the app contents but skip resource forks and metadata
ditto --rsrc --extattr "./bergen.app" "$TEMP_DIR/bergen.app"

echo "🧹 Cleaning special files and attributes..."
# Remove all resource forks, hidden files, and other special files
find "$TEMP_DIR" -type f -name "._*" -delete
find "$TEMP_DIR" -type f -name ".DS_Store" -delete
find "$TEMP_DIR" -name "__MACOSX" -exec rm -rf {} \; 2>/dev/null || true

# Strip all extended attributes from every file
echo "🔧 Stripping extended attributes from all files..."
xattr -cr "$TEMP_DIR/bergen.app"

# Fix permissions
echo "🔧 Fixing permissions..."
find "$TEMP_DIR/bergen.app" -type d -exec chmod 755 {} \;
find "$TEMP_DIR/bergen.app" -type f -exec chmod 644 {} \;
find "$TEMP_DIR/bergen.app" -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true
find "$TEMP_DIR/bergen.app" -path "*/MacOS/*" -type f -exec chmod 755 {} \; 2>/dev/null || true

# Get signing identity
IDENTITY=""
if [ -n "$APPLE_DEVELOPER_ID" ]; then
    IDENTITY="$APPLE_DEVELOPER_ID"
else
    # Try to find a valid identity
    IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application\|Apple Development" | head -1 | sed -E 's/.*[0-9]+\) ([0-9A-F]+) "(.*)"/\2/')
    
    if [ -z "$IDENTITY" ]; then
        echo "❌ No valid signing identity found"
        echo "Please set APPLE_DEVELOPER_ID environment variable or ensure you have a valid developer certificate"
        exit 1
    fi
fi

echo "🔐 Using signing identity: $IDENTITY"

# Sign the app - start with contents
echo "🔐 Signing app contents..."

# Sign frameworks if they exist
FRAMEWORKS_DIR="$TEMP_DIR/bergen.app/Contents/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ]; then
    echo "🔐 Signing frameworks and libraries..."
    find "$FRAMEWORKS_DIR" -type f -name "*.framework" -o -name "*.dylib" | while read -r fw; do
        codesign --force --deep --verbose --options runtime --timestamp --sign "$IDENTITY" "$fw" || true
    done
fi

# Sign all executable files in MacOS directory
MACOS_DIR="$TEMP_DIR/bergen.app/Contents/MacOS"
if [ -d "$MACOS_DIR" ]; then
    echo "🔐 Signing executables in MacOS directory..."
    find "$MACOS_DIR" -type f -exec codesign --force --deep --verbose --options runtime --timestamp --sign "$IDENTITY" {} \; || true
fi

# Finally sign the main app bundle
echo "🔐 Signing main application bundle..."
codesign --force --deep --verbose --options runtime --timestamp --sign "$IDENTITY" "$TEMP_DIR/bergen.app"

# Verify the signature
echo "✅ Verifying signature..."
codesign --verify --verbose "$TEMP_DIR/bergen.app"

# Replace the original app with our rebuilt and signed version
echo "📦 Replacing original app with properly signed version..."
rm -rf ./bergen.app
mv "$TEMP_DIR/bergen.app" ./bergen.app

# Clean up
rm -rf "$TEMP_DIR"

echo "🎉 App has been successfully rebuilt and signed"
echo "You can now create a distribution package with:"
echo "ditto -c -k --keepParent bergen.app bergen-macos.zip"