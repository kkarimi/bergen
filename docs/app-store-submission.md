# Mac App Store Submission Guide

This guide walks you through submitting your Bergen app to the Mac App Store.

## Prerequisites

1. **Apple Developer Account**: You must have an active Apple Developer Program membership
2. **App Store Connect setup**: Ensure your app is created in App Store Connect
3. **Distribution Certificate**: You need an "Apple Distribution" certificate (different from Developer ID)
4. **App Store Profile**: You need an App Store provisioning profile

## Step 1: Prepare for App Store Build

### Create an App Store Distribution Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Click the + button to create a new certificate
3. Select "Apple Distribution" under Software
4. Follow the steps to create and download the certificate
5. Place it in your `cert` directory as `appstore.cer`

### Create a Mac App Store Provisioning Profile

1. Go to [Profiles section](https://developer.apple.com/account/resources/profiles/list)
2. Click the + button to create a new profile
3. Select "Mac App Store" as the distribution method
4. Select your App ID (com.zendo.bergen)
5. Select your Distribution Certificate
6. Name it "Bergen Mac App Store"
7. Download and place it in your `cert` directory as `bergen_appstore.provisionprofile`

## Step 2: Build for App Store

We've already created an App Store build script that handles the process for you:

```bash
# Set environment variables (or use .env file)
export APPLE_TEAM_ID="YOUR_TEAM_ID" 

# Run the App Store build script
npm run appstore-build
# or
./scripts/app-store-build.sh
```

The script will:
1. Build your app with the right certificates and settings
2. Create a signed .app file
3. Package it as a .pkg file ready for submission

## Step 3: Submit to App Store

Once your build is complete, use the dedicated release script:

```bash
# Submit to App Store
npm run appstore-release
# or
./scripts/app-store-release.sh
```

This script will:
1. Validate your package file
2. Ask for confirmation before submission
3. Submit to the App Store using your credentials

If you prefer manual submission, you have these alternatives:

### Using App Store Connect website:

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to your app
3. Click on "App Store" tab
4. Click the + button next to Build
5. Upload your .pkg file
6. Wait for the build to process

### Using Transporter app:

1. Open Transporter app (download from Mac App Store if needed)
2. Sign in with your Apple ID
3. Click the + button to add your .pkg file
4. Click "Deliver" to upload

### Using Terminal manually:

```bash
# Submit using altool
xcrun altool --upload-app -f bergen-appstore-v0.1.5.pkg -t macos -u "your.apple.id@email.com" -p "app-specific-password"
```

## Step 4: Complete App Store Information

After the build is uploaded and processed, complete all required information in App Store Connect:

1. App Information
2. Pricing and Availability 
3. App Privacy
4. Screenshots (at least one)
5. Description, keywords, etc.

Once all information is complete and your build is approved by automated checks, you can submit for App Review.

## Troubleshooting

### Common Issues

1. **Certificate validation failures**: Make sure your certificate is trusted and valid
2. **Provisioning profile issues**: Ensure the profile matches your app bundle ID
3. **App features not allowed**: Some features may not be allowed in App Store apps
4. **Missing information in App Store Connect**: Complete all required metadata
5. **App sandbox issues**: Mac App Store apps must be sandboxed

For more information, check Apple's [App Store submission guidelines](https://developer.apple.com/app-store/review/guidelines/).