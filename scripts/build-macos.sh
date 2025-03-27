#!/bin/bash

# Exit on error
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "🔑 Loading environment variables from .env file..."
    source .env
fi

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
    
    # Use the nuke-and-rebuild script for signing
    echo "🔄 Running nuke-and-rebuild.sh for reliable signing..."
    if ./scripts/nuke-and-rebuild.sh; then
        echo "📋 Installing rebuilt and signed app..."
        cp -R ./bergen.app /Applications/bergen.app
        echo "✅ Rebuilt and signed app installed to /Applications/bergen.app"
            
        # Skip the regular signing process as the app is already signed
        SKIP_REGULAR_SIGNING=true
    else
        echo "⚠️ Nuclear rebuild failed, falling back to regular signing process"
        echo "⚠️ This will likely fail too, but attempting as a fallback..."
        SKIP_REGULAR_SIGNING=false
    fi

    # Only proceed with regular signing if the fix script didn't succeed
    if [ "$SKIP_REGULAR_SIGNING" != "true" ]; then
        # Sign the application with Developer ID
        echo "🔐 Signing the application..."
    
        # Check if certificate exists in cert directory
        CERT_PATH="./cert/development.cer"
        if [ ! -f "$CERT_PATH" ]; then
        echo "⚠️ Certificate not found at $CERT_PATH"
        
        # Fall back to APPLE_DEVELOPER_ID if certificate file not found
        if [ -z "$APPLE_DEVELOPER_ID" ]; then
            echo "⚠️ APPLE_DEVELOPER_ID is not set. Please set it to your Developer ID Application certificate name."
            echo "Example: export APPLE_DEVELOPER_ID=\"Developer ID Application: Your Name (TEAMID)\""
            echo "⚠️ Continuing without code signing. App won't be accepted by Homebrew."
        else
            echo "📝 Signing with certificate identifier: $APPLE_DEVELOPER_ID"
            
            # Sign the app using certificate identifier
            codesign --force --options runtime --sign "$APPLE_DEVELOPER_ID" bergen.app
        fi
    else
        echo "📝 Found certificate at $CERT_PATH"
        
        # Import certificate to keychain if needed
        CERT_SHA1=$(openssl x509 -in "$CERT_PATH" -inform DER -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
        echo "📝 Certificate SHA1: $CERT_SHA1"
        
        # Check if we have APPLE_DEVELOPER_ID in env var
        if [ -z "$APPLE_DEVELOPER_ID" ]; then
            # Extract identity from certificate
            CERT_CN=$(openssl x509 -in "$CERT_PATH" -inform DER -noout -subject | sed -n 's/.*CN=\([^,]*\).*/\1/p')
            echo "📝 Using certificate Common Name: $CERT_CN"
            
            # Fix unsealed contents issue before signing
            find bergen.app -type f -name "._*" -delete
            find bergen.app -type d -name "__MACOSX" -exec rm -r {} \; 2>/dev/null || true
            
            # Sign the app using extracted identity with deep flag
            codesign --force --deep --options runtime --sign "$CERT_CN" bergen.app
        else
            echo "📝 Using provided identity: $APPLE_DEVELOPER_ID"
            
            # Fix unsealed contents issue before signing
            find bergen.app -type f -name "._*" -delete
            find bergen.app -type d -name "__MACOSX" -exec rm -r {} \; 2>/dev/null || true
            
            # Sign the app using provided identity with deep flag
            codesign --force --deep --options runtime --sign "$APPLE_DEVELOPER_ID" bergen.app
        fi
    fi
    
    # Verify the signature
    echo "🔍 Verifying signature..."
    codesign --verify --verbose bergen.app
        
        # Check if notarization is enabled
        if [ "$NOTARIZE" = "true" ]; then
            # Check for required environment variables
            if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
                echo "⚠️ APPLE_ID or APPLE_ID_PASSWORD not set. Skipping notarization."
                echo "To notarize, set: export APPLE_ID=\"your@email.com\" APPLE_ID_PASSWORD=\"app-specific-password\""
            else
                echo "📤 Submitting for notarization..."
                
                # Create a temporary zip for notarization
                NOTARIZE_ZIP="bergen-notarize.zip"
                ditto -c -k --keepParent bergen.app "$NOTARIZE_ZIP"
                
                # Submit for notarization
                xcrun notarytool submit "$NOTARIZE_ZIP" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$(echo $APPLE_DEVELOPER_ID | grep -o '[A-Z0-9]*$')" --wait
                
                # Remove the temporary zip
                rm "$NOTARIZE_ZIP"
                
                # Staple the notarization ticket to the app
                echo "🔖 Stapling notarization ticket to app..."
                xcrun stapler staple bergen.app
                
                echo "✅ App has been notarized and stapled successfully"
            fi
        else
            echo "ℹ️ Notarization skipped. Set NOTARIZE=true to enable."
        fi
    fi

    # Check if a zip file already exists (from nuke-and-rebuild)
    VERSION=$(node -p "require('./package.json').version")
    ZIP_NAME="bergen-macos-v${VERSION}.zip"
    
    if [ ! -f "$ZIP_NAME" ]; then
        # Create a zip file for distribution
        echo "📦 Creating zip file for distribution..."
        ditto -c -k --keepParent bergen.app "$ZIP_NAME"
        echo "✅ Zip file created at $ZIP_NAME"
    else
        echo "✅ Using existing zip file: $ZIP_NAME"
    fi
else
    echo "❌ Build output not found"
    echo "🔍 Searching for the app in all possible locations:"
    find "$DERIVED_DATA_DIR" -name "bergen.app" 2>/dev/null
    exit 1
fi 