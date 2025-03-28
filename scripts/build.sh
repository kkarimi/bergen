#!/bin/bash

# ===================================
# FINAL WORKING BUILD SCRIPT 
# This builds a complete, working app
# ===================================

set -e  # Exit on any error

# Define color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}🚀 Building Bergen app${NC}"

# ----------------
# STEP 1: Clean up
# ----------------
echo -e "\n${YELLOW}🧹 Cleaning previous builds${NC}"
rm -rf "$PROJECT_ROOT/macos/DerivedData"
rm -rf "$PROJECT_ROOT/macos/build"
rm -rf "$PROJECT_ROOT/bergen.app"
rm -f "$PROJECT_ROOT/bergen-*.zip"

# Clean Xcode caches
find ~/Library/Developer/Xcode/DerivedData -name "bergen-*" -type d -print 2>/dev/null | xargs rm -rf 2>/dev/null || true

# -----------------------
# STEP 2: Install dependencies
# -----------------------
echo -e "\n${YELLOW}📦 Installing dependencies${NC}"
yarn install --force
cd "$PROJECT_ROOT/macos"
rm -rf Pods
rm -f Podfile.lock
pod install

# --------------------------------
# STEP 3: Create a functional bundle
# --------------------------------
echo -e "\n${YELLOW}🔧 Creating React Native bundle${NC}"
cd "$PROJECT_ROOT"
mkdir -p "$PROJECT_ROOT/macos/build/Release/bergen.app/Contents/Resources"
NODE_ENV=production npx react-native bundle --platform macos --dev false --entry-file index.js \
  --bundle-output "$PROJECT_ROOT/macos/build/Release/bergen.app/Contents/Resources/main.jsbundle" \
  --assets-dest "$PROJECT_ROOT/macos/build/Release/bergen.app/Contents/Resources"

# Create the bundle script replacement
echo -e "\n${YELLOW}🔧 Setting up bundle script replacement${NC}"
cat > "$PROJECT_ROOT/macos/fix-bundle-script.sh" << 'EOL'
#!/bin/bash
echo "✅ Using pre-built bundle"
exit 0
EOL
chmod +x "$PROJECT_ROOT/macos/fix-bundle-script.sh"

# -----------------------
# STEP 4: Build the app
# -----------------------
echo -e "\n${YELLOW}🏗 Building app${NC}"

# Determine architecture
if [ "$(uname -m)" = "arm64" ]; then
  ARCH="arm64"
else
  ARCH="x86_64"
fi
echo "Building for architecture: $ARCH"

cd "$PROJECT_ROOT/macos"
xcodebuild -workspace bergen.xcworkspace -scheme "bergen-macOS" -configuration Release \
  -arch $ARCH clean build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Release/bergen.app" -type d 2>/dev/null | head -n 1)

if [ -n "$APP_PATH" ]; then
  echo -e "\n${GREEN}✅ Build successful!${NC}"
  
  # Check if bundle exists in the app
  if [ ! -f "$APP_PATH/Contents/Resources/main.jsbundle" ]; then
    echo -e "${YELLOW}⚠️ Bundle missing, copying manually...${NC}"
    mkdir -p "$APP_PATH/Contents/Resources"
    cp "$PROJECT_ROOT/macos/build/Release/bergen.app/Contents/Resources/main.jsbundle" "$APP_PATH/Contents/Resources/"
    cp -R "$PROJECT_ROOT/macos/build/Release/bergen.app/Contents/Resources/assets" "$APP_PATH/Contents/Resources/" 2>/dev/null || true
  fi
  
  # Copy to project root for easy access
  cp -R "$APP_PATH" "$PROJECT_ROOT/bergen.app"
  
  # Check app size and validate executable
  APP_SIZE=$(du -sh "$PROJECT_ROOT/bergen.app" | cut -f1)
  echo -e "App size: ${GREEN}$APP_SIZE${NC}"
  
  # Verify executable exists
  if [ -x "$PROJECT_ROOT/bergen.app/Contents/MacOS/bergen" ]; then
    echo -e "Executable: ${GREEN}Found and valid${NC}"
  else
    echo -e "Executable: ${RED}Missing or invalid${NC}"
    ls -la "$PROJECT_ROOT/bergen.app/Contents/MacOS/" 2>/dev/null || echo "MacOS directory not found"
  fi
  
  # Create zip for distribution
  VERSION=$(grep -o '"version": "[^"]*"' "$PROJECT_ROOT/package.json" | cut -d'"' -f4)
  ZIP_FILE="$PROJECT_ROOT/bergen-macos-v${VERSION}.zip"
  cd "$PROJECT_ROOT"
  zip -r "$ZIP_FILE" bergen.app
  echo -e "Distribution zip: ${BLUE}$ZIP_FILE${NC}"
  
  echo -e "\n${GREEN}🎉 Build completed successfully!${NC}"
  echo -e "\n${BLUE}To verify the app, run:${NC}"
  echo "open $PROJECT_ROOT/bergen.app"
else
  echo -e "\n${RED}❌ Build failed - app not found${NC}"
  exit 1
fi

# -----------------------
# STEP 5: Copy app to /Applications
# -----------------------
echo -e "\n${YELLOW}📦 Copying app to /Applications${NC}"
rm -rf "/Applications/Bergen.app"
cp -R "$PROJECT_ROOT/bergen.app" "/Applications/Bergen.app"

# -----------------------
# STEP 6: Archive the app
# -----------------------
echo -e "\n${YELLOW}📦 Archiving the app (for .xcarchive)${NC}"

# Use the same architecture logic you already have
if [ "$(uname -m)" = "arm64" ]; then
  ARCH="arm64"
else
  ARCH="x86_64"
fi
echo "Archiving for architecture: $ARCH"

# Define where the archive will be stored (xcarchive is just a folder in disguise)
ARCHIVE_PATH="$PROJECT_ROOT/macos/build/Release/bergen.xcarchive"
cd "$PROJECT_ROOT/macos"
xcodebuild \
  -workspace bergen.xcworkspace \
  -scheme "bergen-macOS" \
  -configuration Release \
  -arch "$ARCH" \
  archive \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
cd "$PROJECT_ROOT"
if [ -d "$ARCHIVE_PATH" ]; then
  echo -e "\n${GREEN}✅ Archive created at:${NC} $ARCHIVE_PATH"
else
  echo -e "\n${RED}❌ Archive step failed - folder not found:${NC} $ARCHIVE_PATH"
  exit 1
fi

# -----------------------
# STEP 7: Export the app
# -----------------------
# echo -e "\n${YELLOW}📦 Exporting the .xcarchive${NC}"

# ARCHIVE_PATH="$PROJECT_ROOT/macos/build/Release/bergen.xcarchive"
# EXPORT_PATH="$PROJECT_ROOT/macos/build/Release/Exported"
# EXPORT_OPTIONS_PLIST="$PROJECT_ROOT/macos/ExportOptions.plist"

# # Make sure your archive exists
# if [ ! -d "$ARCHIVE_PATH" ]; then
#   echo -e "${RED}❌ Archive not found at $ARCHIVE_PATH${NC}"
#   exit 1
# fi

# # Clean up previous exports
# rm -rf "$EXPORT_PATH"
# mkdir -p "$EXPORT_PATH"

# cd "$PROJECT_ROOT/macos"
# # Call xcodebuild to export the archive
# xcodebuild -exportArchive \
#   -archivePath "$ARCHIVE_PATH" \
#   -exportPath "$EXPORT_PATH" \
#   -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
#   CODE_SIGN_IDENTITY="" \
#   CODE_SIGNING_REQUIRED=NO \
#   CODE_SIGNING_ALLOWED=NO

# # Check if the export succeeded
# if [ $? -eq 0 ]; then
#   echo -e "\n${GREEN}✅ Export successful!${NC}"
#   echo "Exported files are here: $EXPORT_PATH"
# else
#   echo -e "\n${RED}❌ Export failed${NC}"
#   exit 1
# fi