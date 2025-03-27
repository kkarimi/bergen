# Homebrew Distribution Guide

This document explains how to distribute your app via Homebrew and alternative approaches when facing Homebrew's popularity requirements.

## Understanding Homebrew's Popularity Requirements

Homebrew has a policy requiring that software in its main repository meets certain popularity criteria:
- 30+ GitHub forks
- 30+ GitHub watchers
- 75+ GitHub stars

If your repository doesn't meet these criteria, Homebrew will reject your cask submission with:
`GitHub repository not notable enough (<30 forks, <30 watchers and <75 stars)`

## Options for Distribution

### Option 1: Increase Repository Popularity

The most straightforward approach is to grow your GitHub repository's popularity:

1. Promote your app on relevant forums, Reddit, Twitter, etc.
2. Add valuable features to attract more users
3. Write blog posts about your app
4. Create tutorial videos showing how to use your app

### Option 2: Create Your Own Homebrew Tap

A Homebrew "tap" is simply a repository of formulae and casks. You can create your own tap:

1. Create a public GitHub repository named `homebrew-bergen` (notice the prefix `homebrew-`)
2. Add your cask file to `Casks/bergen.rb` in this repository
3. Users can then install with:
   ```bash
   brew tap kkarimi/bergen
   brew install kkarimi/bergen/bergen
   ```

#### Steps to Create Your Own Tap:

```bash
# Create the repository
mkdir -p homebrew-bergen/Casks
cd homebrew-bergen

# Copy your cask file
cp /Users/nima/dev/personal/bergen/homebrew-cask/Casks/b/bergen.rb Casks/

# Initialize git repository
git init
git add .
git commit -m "Initial commit with bergen cask"

# Create GitHub repository and push
gh repo create kkarimi/homebrew-bergen --public
git remote add origin https://github.com/kkarimi/homebrew-bergen.git
git push -u origin main
```

Then update your README with installation instructions.

### Option 3: Alternative Distribution Methods

1. **Direct download links**: Provide direct download links from your GitHub releases page

2. **MacPorts**: Submit your app to MacPorts, which has different requirements

3. **Mac App Store**: Consider distributing through the Mac App Store (requires additional work for app review)

## Requirements for Code Signing

Remember that macOS apps need to be properly signed and notarized for distribution:

1. Sign your app with a Developer ID certificate
2. Notarize your app with Apple's notarization service
3. Staple the notarization ticket to your app

Follow the instructions in [SIGNING-INSTRUCTIONS.md](/SIGNING-INSTRUCTIONS.md) for details.

## Troubleshooting Homebrew Submissions

If your cask is rejected for reasons other than popularity, common issues include:

1. **Version mismatch**: Make sure your app's version in Info.plist matches the cask version
2. **Missing or incorrect macOS version dependency**: Use `depends_on macos: ">= :big_sur"` if needed
3. **Signature verification**: Ensure your app is properly signed and notarized

## Resources

- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [Creating a tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [macOS Code Signing](https://developer.apple.com/documentation/xcode/signing-your-app-automatically)
- [Notarizing macOS Software](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution)