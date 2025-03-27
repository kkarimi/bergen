#!/bin/bash

# Exit on error
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "🔑 Loading environment variables from .env file..."
    source .env
fi

echo "🏗 Building React Native macOS app for App Store submission..."

# Check for required variables
if [ -z "$APPLE_TEAM_ID" ]; then
    echo "⚠️ APPLE_TEAM_ID is not set in your .env file"
    echo "Example: APPLE_TEAM_ID=\"ABC123DEF45\""
    exit 1
fi

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

# Build the React Native macOS app for App Store
echo "🚀 Building macOS app for App Store..."
xcodebuild -workspace bergen.xcworkspace -scheme "bergen-macOS" -configuration Release \
    -archivePath "build/bergen.xcarchive" archive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    CODE_SIGN_STYLE="Manual" \
    PRODUCT_BUNDLE_IDENTIFIER="com.zendo.bergen"

# Export the archive for App Store
echo "📦 Exporting archive for App Store..."

# Create exportOptions.plist file
cat > exportOptions.plist << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.zendo.bergen</key>
        <string>Bergen Mac App Store</string>
    </dict>
</dict>
</plist>
EOL

# Export the archive
xcodebuild -exportArchive -archivePath "build/bergen.xcarchive" \
    -exportPath "build/App Store" \
    -exportOptionsPlist exportOptions.plist

cd ..

# Check if the export was successful
APP_PATH="macos/build/App Store/bergen.app"
if [ -d "$APP_PATH" ]; then
    echo "✅ Export completed successfully!"
    echo "📍 The app can be found at: $APP_PATH"
    
    # Create a symlink in the project root for easy access
    ln -sf "$APP_PATH" ./bergen.app
    echo "🔗 Symlink created at ./bergen.app for easy access"

    # Create a PKG file for App Store submission
    echo "📦 Creating PKG file for App Store submission..."
    VERSION=$(node -p "require('../package.json').version")
    PKG_NAME="bergen-appstore-v${VERSION}.pkg"
    
    # Check if we should use app-specific certificate
    if [ -n "$APPLE_INSTALLER_CERT" ]; then
        productbuild --component "$APP_PATH" /Applications --sign "$APPLE_INSTALLER_CERT" "$PKG_NAME"
    else
        productbuild --component "$APP_PATH" /Applications "$PKG_NAME"
    fi
    
    echo "✅ PKG file created at $PKG_NAME"
    
    # Instructions for submission
    echo "🚀 Your app has been built and packaged for the App Store!"
    echo "📦 PKG file is ready at: $PKG_NAME"
    echo ""
    echo "To submit to the App Store, run:"
    echo "./app-store-release.sh"
else
    echo "❌ Export failed"
    echo "🔍 Check the Xcode logs for more information"
    exit 1
fi