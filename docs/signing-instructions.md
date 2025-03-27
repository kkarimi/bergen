# macOS App Signing and Notarization Instructions

To properly sign and notarize your Bergen macOS app for Homebrew distribution, follow these steps:

## Prerequisites

1. **Apple Developer Account**: You must have an Apple Developer account (https://developer.apple.com/)
2. **Developer ID Certificate**: Create a "Developer ID Application" certificate in your Apple Developer account
3. **App-Specific Password**: Generate an app-specific password for your Apple ID at https://appleid.apple.com/

## Certificate Installation

If you've downloaded your Developer ID certificate from Apple, you can install it using the provided script:

1. **Place the certificate in the cert directory:**
   - Save your certificate as `cert/development.cer`
   - If you have a private key, save it as `cert/private_key.p12`

2. **Run the installation script:**
   ```bash
   npm run install-cert
   # or
   ./scripts/install-certificate.sh
   ```

   This script will:
   - Install the certificate into your keychain
   - Install the private key (if provided)
   - Update your .env file with the certificate information

## Signing and Notarizing Process

The updated `build-macos.sh` script now includes code signing and notarization capabilities. To use it:

### 1. Set up your environment variables:

Copy the `.env.example` file to `.env` and edit it with your credentials (if you haven't used the certificate installation script):

```bash
cp .env.example .env
```

Then modify `.env` with your information:

```
# Required for signing
APPLE_DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"

# Required for notarization (optional but recommended)
NOTARIZE=true
APPLE_ID="your.email@example.com"
APPLE_ID_PASSWORD="your-app-specific-password"
```

- `APPLE_DEVELOPER_ID` should match your Developer ID certificate exactly
- `APPLE_ID` is your Apple Developer account email
- `APPLE_ID_PASSWORD` should be an app-specific password, not your main Apple ID password

### 2. Run the build script:

```bash
npm run build
# or
./scripts/build-macos.sh
```

The script will:
1. Build the macOS app
2. Sign it with your Developer ID certificate
3. If notarization is enabled, submit it to Apple for notarization
4. Staple the notarization ticket to the app
5. Create a properly signed and notarized zip file for distribution

### 3. Verify the signature:

```bash
codesign -dvv /Applications/bergen.app
```

You should see output confirming the app is signed and notarized.

## Troubleshooting

### Certificate issues

If you see certificate errors:

1. Check your certificate in Keychain Access
2. Verify the certificate name in your environment variable matches exactly
3. Ensure your certificate is valid and not expired

```bash
security find-identity -v -p codesigning
```

### Notarization issues

If notarization fails:

1. Check Apple's notarization logs (the command outputs a URL)
2. Verify your app-specific password is correct
3. Ensure your bundle identifier in Info.plist is consistent

## Resources

- [Apple's Code Signing Guide](https://developer.apple.com/documentation/security/code_signing)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)