#!/bin/bash

# A nuclear option for fixing code signing issues
# This script completely rebuilds the app from scratch in a clean directory

set -e

echo "☢️ NUCLEAR OPTION: Complete App Rebuild and Sign ☢️"
echo "This script will completely rebuild the app from scratch"

# Check for the app
if [ ! -d "./bergen.app" ]; then
    echo "❌ Error: bergen.app not found in current directory"
    exit 1
fi

# Get signing identity
if [ -n "$APPLE_DEVELOPER_ID" ]; then
    IDENTITY="$APPLE_DEVELOPER_ID"
else
    IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | sed -E 's/.*[0-9]+\) ([0-9A-F]+) "(.*)"/\2/')
    
    if [ -z "$IDENTITY" ]; then
        echo "❌ No valid signing identity found"
        exit 1
    fi
fi

echo "🔑 Using identity: $IDENTITY"

# Create a completely fresh directory structure
WORK_DIR="/tmp/bergen_rebuild_$(date +%s)"
mkdir -p "$WORK_DIR"
APP_DIR="$WORK_DIR/bergen.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🏗 Creating fresh app structure in $WORK_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Extract Info.plist and other essential files
echo "📄 Extracting essential files..."
cp -R "./bergen.app/Contents/Info.plist" "$CONTENTS_DIR/"

# Copy executable
if [ -f "./bergen.app/Contents/MacOS/bergen" ]; then
    echo "📄 Copying main executable..."
    cp "./bergen.app/Contents/MacOS/bergen" "$MACOS_DIR/"
    chmod 755 "$MACOS_DIR/bergen"
fi

# Copy resources directory contents (excluding problematic files)
echo "📄 Copying resources..."
rsync -a --exclude "._*" --exclude ".DS_Store" --exclude "__MACOSX" "./bergen.app/Contents/Resources/" "$RESOURCES_DIR/"

# Copy any other necessary directories
for dir in Frameworks PlugIns; do
    if [ -d "./bergen.app/Contents/$dir" ]; then
        echo "📄 Copying $dir..."
        mkdir -p "$CONTENTS_DIR/$dir"
        rsync -a --exclude "._*" --exclude ".DS_Store" --exclude "__MACOSX" "./bergen.app/Contents/$dir/" "$CONTENTS_DIR/$dir/"
    fi
done

# Fix permissions
echo "🔧 Setting correct permissions..."
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;
find "$MACOS_DIR" -type f -exec chmod 755 {} \;
if [ -d "$CONTENTS_DIR/Frameworks" ]; then
    find "$CONTENTS_DIR/Frameworks" -name "*.framework" -type d -exec chmod 755 {} \;
    find "$CONTENTS_DIR/Frameworks" -name "*.dylib" -type f -exec chmod 755 {} \;
fi

# Remove extended attributes from all files
echo "🧹 Removing extended attributes..."
xattr -cr "$APP_DIR"

# Sign the app
echo "🔐 Signing the app..."

# Sign frameworks if they exist
if [ -d "$CONTENTS_DIR/Frameworks" ]; then
    echo "🔐 Signing frameworks..."
    find "$CONTENTS_DIR/Frameworks" -name "*.framework" -o -name "*.dylib" | while read -r fw; do
        echo "📝 Signing $fw"
        codesign --force --sign "$IDENTITY" --timestamp --options runtime "$fw"
    done
fi

# Sign the main executable
if [ -f "$MACOS_DIR/bergen" ]; then
    echo "🔐 Signing main executable..."
    codesign --force --sign "$IDENTITY" --timestamp --options runtime "$MACOS_DIR/bergen"
fi

# Sign the app bundle
echo "🔐 Signing app bundle..."
if [ -f "./macos/bergen-macos/bergen.entitlements" ]; then
    codesign --force --sign "$IDENTITY" --timestamp --options runtime --entitlements "./macos/bergen-macos/bergen.entitlements" "$APP_DIR"
else
    # Fall back to signing without entitlements if file not found
    codesign --force --sign "$IDENTITY" --timestamp --options runtime "$APP_DIR"
fi

# Verify the signature
echo "✅ Verifying signature..."
codesign --verify --verbose "$APP_DIR"

# Copy back to current directory
echo "📦 Copying rebuilt app back to current directory..."
rm -rf ./bergen.app
cp -R "$APP_DIR" ./bergen.app

# Clean up
rm -rf "$WORK_DIR"

echo "✅ App rebuild and signing complete!"
echo "The app has been completely rebuilt and should be properly signed."
echo ""
echo "📦 Creating zip archive..."
VERSION=$(node -p "require('../package.json').version")
ZIP_NAME="bergen-macos-v${VERSION}.zip"
ditto -c -k --keepParent bergen.app "$ZIP_NAME"
echo "✅ Zip file created at $ZIP_NAME"