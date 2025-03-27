#!/bin/bash

# generate-icons.sh - Automated icon generation for Bergen macOS app
# Usage: ./generate-icons.sh [path_to_source_icon.png]
#
# This script:
# 1. Generates all required icon sizes for macOS app from a source PNG
# 2. Places them in the correct location in the app bundle
# 3. Updates the README.md to reference the new icon

set -e

# Default source icon path
SOURCE_ICON="${1:-./assets/newicon.png}"
TEMP_DIR="$(mktemp -d)"
ICON_SET_PATH="./macos/bergen-macos/Assets.xcassets/AppIcon.appiconset"

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed. Please install it first."
  echo "You can install it using Homebrew: brew install ffmpeg"
  exit 1
fi

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
  echo "Error: Source icon not found at $SOURCE_ICON"
  exit 1
fi

echo "🖼  Generating macOS icons from $SOURCE_ICON..."

# Create all required icon sizes
SIZES=(
  "16;icon_16x16.png"
  "32;icon_16x16@2x.png"
  "32;icon_32x32.png"
  "64;icon_32x32@2x.png"
  "128;icon_128x128.png"
  "256;icon_128x128@2x.png"
  "256;icon_256x256.png"
  "512;icon_256x256@2x.png"
  "512;icon_512x512.png"
  "1024;icon_512x512@2x.png"
)

for SIZE_PAIR in "${SIZES[@]}"; do
  SIZE=$(echo $SIZE_PAIR | cut -d ';' -f 1)
  FILENAME=$(echo $SIZE_PAIR | cut -d ';' -f 2)
  echo "  - Generating $FILENAME ($SIZE x $SIZE px)"
  ffmpeg -loglevel error -i "$SOURCE_ICON" -vf "scale=$SIZE:$SIZE" "$TEMP_DIR/$FILENAME"
done

# Copy icons to AppIcon.appiconset
echo "📦 Copying icons to $ICON_SET_PATH..."
cp "$TEMP_DIR"/*.png "$ICON_SET_PATH/"

# Update README to use the new icon
echo "📄 Updating README.md to reference new icon..."
if grep -q "assets/icon.png" README.md; then
  # Get the filename from the source icon path
  NEW_ICON_NAME=$(basename "$SOURCE_ICON")
  
  # Update the README.md file
  sed -i '' "s|assets/icon.png|assets/$NEW_ICON_NAME|g" README.md
  echo "  - README.md updated to use assets/$NEW_ICON_NAME"
else
  echo "  - No reference to icon.png found in README.md, skipping update"
fi

# Create a copy of the source icon in assets directory if needed
if [ "$SOURCE_ICON" != "./assets/newicon.png" ]; then
  echo "📝 Copying source icon to assets directory..."
  cp "$SOURCE_ICON" "./assets/newicon.png"
  echo "  - Source icon copied to ./assets/newicon.png"
fi

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "✅ Icon generation complete!"
echo "To build the app with the new icons, run: yarn macos"