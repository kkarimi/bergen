#!/bin/bash

# Exit on error
set -e

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "brew install gh"
    exit 1
fi

# Check if logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "❌ Please login to GitHub CLI first:"
    echo "gh auth login"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Get the remote repository URL
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REPO_URL" ]; then
    echo "❌ No git remote 'origin' found"
    exit 1
fi

echo "📦 Using repository: $REPO_URL"

# Ensure working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "❌ Working directory is not clean. Please commit or stash changes first."
    exit 1
fi

# Build the app
echo "🏗 Building the app..."
./build-macos.sh

# Get the version from package.json
VERSION=$(node -p "require('./package.json').version")
ZIP_NAME="bergen-macos-v${VERSION}.zip"

# Check if tag already exists
if git rev-parse "v${VERSION}" &> /dev/null; then
    echo "❌ Tag v${VERSION} already exists. Please update version in package.json"
    exit 1
fi

# Check if zip file exists
if [ ! -f "$ZIP_NAME" ]; then
    echo "❌ Build artifact not found: $ZIP_NAME"
    exit 1
fi

# Create GitHub release
echo "🚀 Creating GitHub release v${VERSION}..."
gh release create "v${VERSION}" \
    --title "Bergen v${VERSION}" \
    --notes "Release notes for version ${VERSION}" \
    --draft \
    "$ZIP_NAME"

echo "✅ Draft release v${VERSION} created successfully!"
echo "📦 Binary uploaded to GitHub releases"
echo "🌎 Please review the release at: $REPO_URL/releases"
echo "   Once reviewed, you can publish it from the GitHub web interface" 