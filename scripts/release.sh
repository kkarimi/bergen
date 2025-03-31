#!/bin/bash

# Exit on error
set -e

# Function to print usage
print_usage() {
    echo "Usage: $0 [--bump-type <patch|minor|major>] [--publish-cask] [--no-build]"
    echo "Default bump type is patch"
    exit 1
}

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Parse command line arguments
BUMP_TYPE="patch"
PUBLISH_CASK=true
NO_BUILD=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --bump-type) BUMP_TYPE="$2"; shift ;;
        --publish-cask) PUBLISH_CASK=true ;;
        --no-build) NO_BUILD=true ;;
        *) print_usage ;;
    esac
    shift
done

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo "❌ Invalid bump type. Must be patch, minor, or major"
    print_usage
fi

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
# Get current version from package.json
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo "📝 Current version: $CURRENT_VERSION"

# Bump version using node
NEW_VERSION=$(node -e "
const [major, minor, patch] = '${CURRENT_VERSION}'.split('.');
const bumpType = '${BUMP_TYPE}';
let newVersion;
if (bumpType === 'major') {
    newVersion = \`\${Number(major) + 1}.0.0\`;
} else if (bumpType === 'minor') {
    newVersion = \`\${major}.\${Number(minor) + 1}.0\`;
} else {
    newVersion = \`\${major}.\${minor}.\${Number(patch) + 1}\`;
}
console.log(newVersion);
")

echo "🔼 Bumping version from $CURRENT_VERSION to $NEW_VERSION"

# Update version in package.json
node -e "
const fs = require('fs');
const package = require('./package.json');
package.version = '${NEW_VERSION}';
fs.writeFileSync('./package.json', JSON.stringify(package, null, 2) + '\n');
"

# Update version in README.md download link
echo "📝 Updating version in README.md download link..."
sed -i '' "s|/releases/latest/download/bergen-macos-v[0-9]*\.[0-9]*\.[0-9]*\.zip|/releases/latest/download/bergen-macos-v${NEW_VERSION}.zip|g" README.md

# Commit the version bump
git add package.json README.md
git commit -m "chore: bump version to v${NEW_VERSION}"

# Build the app if --no-build is not specified
if [ "$NO_BUILD" = false ]; then
    echo "🏗 Building the app..."
    ./scripts/build.sh
else
    echo "🏗 Skipping build as --no-build was specified"
fi

ZIP_NAME="bergen-macos-v${NEW_VERSION}.zip"

# Check if zip file exists (only if we're not skipping the build)
if [ "$NO_BUILD" = false ] && [ ! -f "$ZIP_NAME" ]; then
    echo "❌ Build artifact not found: $ZIP_NAME"
    exit 1
fi

# Create Git Tag
git tag "v${NEW_VERSION}"
git push origin "v${NEW_VERSION}"

# Create GitHub release
echo "🚀 Creating GitHub release v${NEW_VERSION}..."

if [ "$NO_BUILD" = false ]; then
    gh release create "v${NEW_VERSION}" \
        --title "Bergen v${NEW_VERSION}" \
        --notes "Release notes for version ${NEW_VERSION}" \
        --draft \
        "$ZIP_NAME"
else
    gh release create "v${NEW_VERSION}" \
        --title "Bergen v${NEW_VERSION}" \
        --notes "Release notes for version ${NEW_VERSION}" \
        --draft
fi

echo "✅ Release v${NEW_VERSION} created successfully!"
echo "📦 Binary uploaded to GitHub releases"
echo "🌎 Please review the release at: $REPO_URL/releases"

# Push all changes to origin
echo "🚀 Pushing all changes to origin..."
git push origin main

# If --publish-cask flag is provided, publish to Homebrew cask
if $PUBLISH_CASK; then
    echo "🍺 Publishing to Homebrew cask..."

    # Check if publish-cask.sh exists and is executable
    if [ ! -x "./scripts/publish-cask.sh" ]; then
        echo "❌ scripts/publish-cask.sh not found or not executable"
        echo "   Please make it executable with: chmod +x ./scripts/publish-cask.sh"
        exit 1
    fi

    # Publish the cask
    ./scripts/publish-cask.sh
fi
