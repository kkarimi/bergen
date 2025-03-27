# App Store Information

This file contains important information for the Bergen macOS app store distribution and signing.

## App Identification

- **Bundle ID**: com.zendo.bergen
- **SKU**: bergen.macos
- **Apple ID**: 6743875235
- **App Name**: Bergen Markdown Reader

## Signing Information

When signing the app for App Store or Homebrew distribution, use these values in your `.env` file:

```
# For App Store signing
APPLE_TEAM_ID="YOUR_TEAM_ID"
APPLE_DEVELOPER_ID="Developer ID Application: Your Name (YOUR_TEAM_ID)"

# For notarization
NOTARIZE=true
APPLE_ID="your.apple.id@email.com"
APPLE_ID_PASSWORD="your-app-specific-password"
```

## Build Commands

### For App Store Submission
```bash
# First, ensure your .env file is set up properly
cp .env.example .env
# Edit .env with your credentials

# Then build for App Store
./app-store-build.sh
```

### For Homebrew Distribution
```bash
# First, ensure your .env file is set up properly
cp .env.example .env
# Edit .env with your credentials

# Then build, sign, and notarize
./build-macos.sh

# Create your own Homebrew tap if needed
./CREATE-HOMEBREW-TAP.sh
```

## App Store Details

### Description
Bergen is a beautiful, minimal Markdown reader for macOS. It provides a clean, distraction-free environment for reading markdown documents with support for code syntax highlighting and Mermaid diagrams.

### Keywords
markdown, reader, editor, mermaid, diagrams, documentation, notes, writing, text, documents

### Support URL
https://github.com/kkarimi/bergen/issues

### Marketing URL
https://github.com/kkarimi/bergen

### Privacy Policy URL
https://github.com/kkarimi/bergen/blob/main/PRIVACY.md

## Version Tracking

Remember to keep your version numbers consistent across:
1. package.json
2. Info.plist (CFBundleShortVersionString)
3. Homebrew cask files