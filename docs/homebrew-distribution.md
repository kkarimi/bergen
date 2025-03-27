# Homebrew Distribution Guide

This document explains how to distribute your app via Homebrew and alternative approaches when facing Homebrew's popularity requirements.

## Understanding Homebrew's Popularity Requirements

Homebrew has a policy requiring that software in its main repository meets certain popularity criteria:
- 30+ GitHub forks
- 30+ GitHub watchers
- 75+ GitHub stars

If your repository doesn't meet these criteria, Homebrew will reject your cask submission with:
`GitHub repository not notable enough (<30 forks, <30 watchers and <75 stars)`

## Preparing for Homebrew Distribution

Before submitting to Homebrew, ensure your app is properly signed and notarized:

1. Follow the steps in [signing-instructions.md](./signing-instructions.md) to set up code signing
2. Create a .env file with your signing credentials:
   ```bash
   cp .env.example .env
   # Edit the .env file with your credentials
   ```
3. Build and sign your app:
   ```bash
   npm run build
   # or
   ./scripts/build-macos.sh
   ```

## Options for Distribution

### Option 1: Increase Repository Popularity

The most straightforward approach is to grow your GitHub repository's popularity:

1. Promote your app on relevant forums, Reddit, Twitter, etc.
2. Add valuable features to attract more users
3. Write blog posts about your app
4. Create tutorial videos showing how to use your app

### Option 2: Create Your Own Homebrew Tap

A Homebrew "tap" is simply a repository of formulae and casks. You can create your own tap:

```bash
# Run the provided script to create your own tap
npm run create-homebrew-tap
# or
./scripts/CREATE-HOMEBREW-TAP.sh
```

This script will:
1. Create a new GitHub repository named `homebrew-bergen`
2. Add your cask file with the proper format and bundle ID
3. Push it to your GitHub account

Users can then install with:
```bash
brew tap kkarimi/bergen
brew install kkarimi/bergen/bergen
```

### Option 3: Alternative Distribution Methods

1. **Direct download links**: Provide direct download links from your GitHub releases page
2. **MacPorts**: Submit your app to MacPorts, which has different requirements
3. **Mac App Store**: Consider distributing through the Mac App Store using [app-store-submission.md](./app-store-submission.md)

## Troubleshooting Homebrew Submissions

If your cask is rejected for reasons other than popularity, common issues include:

1. **Code signing issues**: Ensure your app is properly signed with a Developer ID certificate
2. **Notarization issues**: Make sure your app is notarized with Apple
3. **Version mismatch**: Make sure your app's version in Info.plist matches the cask version
4. **Missing or incorrect macOS version dependency**: Use `depends_on macos: ">= :big_sur"` if needed

## Updating Your Homebrew Cask

When releasing a new version:

1. Update the package.json version
2. Build and sign the new version
3. Create a new GitHub release
4. Update your cask file with the new version and SHA256
5. If using your own tap, commit and push the changes

For the official Homebrew cask repository, you'll need to submit a pull request with the updated cask file.