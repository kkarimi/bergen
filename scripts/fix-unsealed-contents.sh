#!/bin/bash

# Exit on error
set -e

echo "🧹 Cleaning unsealed contents from Bergen.app..."

# Check if bergen.app exists
if [ ! -d "./bergen.app" ]; then
    echo "❌ Error: bergen.app not found in the current directory"
    exit 1
fi

# Remove all resource forks and hidden files
echo "🔍 Removing resource forks and hidden files..."
find ./bergen.app -type f -name "._*" -delete
find ./bergen.app -type f -name ".DS_Store" -delete
find ./bergen.app -type d -name "__MACOSX" -exec rm -rf {} \; 2>/dev/null || true

# Strip all extended attributes
echo "🔍 Stripping extended attributes..."
xattr -cr ./bergen.app

# Fix permissions
echo "🔍 Fixing permissions..."
chmod -R 755 ./bergen.app
find ./bergen.app -type f -exec chmod 644 {} \;
find ./bergen.app -name "*.sh" -exec chmod 755 {} \;
find ./bergen.app -name "*.dylib" -exec chmod 755 {} \;

# Create a cleaned copy of the app
echo "🔄 Creating a cleaned copy..."
rm -rf ./bergen_clean.app 2>/dev/null || true
cp -R ./bergen.app ./bergen_clean.app

# Sign the cleaned app
echo "🔐 Signing the cleaned app..."
if [ -n "$APPLE_DEVELOPER_ID" ]; then
    SIGNING_IDENTITY="$APPLE_DEVELOPER_ID"
else
    SIGNING_IDENTITY="Apple Development: Nima Karimi (94N4RGVMTH)"
fi

echo "📝 Using identity: $SIGNING_IDENTITY"

# Sign all frameworks first
echo "🔍 Signing frameworks and libraries..."
find ./bergen_clean.app/Contents/Frameworks -type f -name "*.framework" -o -name "*.dylib" | while read -r framework; do
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$framework"
done

# Sign the app itself
echo "🔍 Signing main application bundle..."
codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" ./bergen_clean.app

# Verify the signature
echo "✅ Verifying signature..."
codesign --verify --verbose ./bergen_clean.app

# Success!
echo "✅ Cleaned and signed app is at ./bergen_clean.app"
echo "🎉 You can now install it to /Applications:"
echo "cp -R ./bergen_clean.app /Applications/bergen.app"