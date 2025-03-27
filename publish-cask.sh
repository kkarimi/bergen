#!/bin/bash

# Exit on error
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage
print_usage() {
    echo "Usage: $0"
    echo "This script creates and submits a Homebrew cask for bergen app"
    exit 1
}

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed. Please install it first:${NC}"
    echo "brew install gh"
    exit 1
fi

# Check if brew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Get current version from package.json
VERSION=$(node -p "require('./package.json').version")
echo -e "${BLUE}📝 Current version: ${VERSION}${NC}"

# Get GitHub repository information
REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's|^git@github.com:|https://github.com/|')
REPO_OWNER=$(echo $REPO_URL | sed -E 's|https://github.com/([^/]+)/.*|\1|')
REPO_NAME=$(echo $REPO_URL | sed -E 's|https://github.com/[^/]+/([^/]+).*|\1|')

echo -e "${BLUE}📦 Using repository: ${REPO_URL}${NC}"

# Define the ZIP filename and paths
ZIP_NAME="bergen-macos-v${VERSION}.zip"
APP_NAME="bergen"

# Check if the release exists
if ! gh release view "v${VERSION}" &> /dev/null; then
    echo -e "${RED}❌ Release v${VERSION} does not exist. Run the release script first.${NC}"
    exit 1
fi

# Download the ZIP file if it doesn't exist locally
if [ ! -f "$ZIP_NAME" ]; then
    echo -e "${YELLOW}🔍 ZIP file not found locally, downloading from GitHub releases...${NC}"
    gh release download "v${VERSION}" -p "$ZIP_NAME"
fi

# Calculate the SHA256 hash of the ZIP file
SHA256=$(shasum -a 256 "$ZIP_NAME" | awk '{print $1}')
echo -e "${GREEN}✅ SHA256: ${SHA256}${NC}"

# Clone homebrew-cask-versions repository if it doesn't exist
HOMEBREW_TAP_DIR="$(brew --repository)/Library/Taps/homebrew/homebrew-cask"
if [ ! -d "$HOMEBREW_TAP_DIR" ]; then
    echo -e "${YELLOW}🔍 Homebrew Cask tap not found, cloning...${NC}"
    # brew tap homebrew/cask
fi

# Fork the homebrew-cask repository if not already forked
if ! gh repo view "$REPO_OWNER/homebrew-cask" &> /dev/null; then
    echo -e "${YELLOW}🍴 Forking homebrew-cask repository...${NC}"
    gh repo fork homebrew/homebrew-cask --clone=false
fi

# Clone your fork of homebrew-cask if not already cloned
FORK_DIR="./homebrew-cask"
if [ ! -d "$FORK_DIR" ]; then
    echo -e "${YELLOW}🔍 Cloning your fork of homebrew-cask...${NC}"
    git clone "https://github.com/$REPO_OWNER/homebrew-cask.git" "$FORK_DIR"
    cd "$FORK_DIR"
    git remote add upstream https://github.com/homebrew/homebrew-cask.git
    cd ..
else
    echo -e "${BLUE}📁 Using existing homebrew-cask clone...${NC}"
    cd "$FORK_DIR"
    git checkout master
    git pull upstream master
    git push origin master
    cd ..
fi

# Create a new branch for the PR
BRANCH_NAME="add-$APP_NAME-$VERSION"
cd "$FORK_DIR"
git checkout -b "$BRANCH_NAME"

# Create the Cask file
CASK_PATH="Casks/b/$APP_NAME.rb"
mkdir -p "$(dirname "$CASK_PATH")"

echo -e "${BLUE}📝 Creating cask file at $CASK_PATH...${NC}"
cat > "$CASK_PATH" << EOL
cask "$APP_NAME" do
  version "$VERSION"
  sha256 "$SHA256"

  url "$REPO_URL/releases/download/v#{version}/$ZIP_NAME"
  name "Bergen"
  desc "A React Native macOS app for Markdown viewing"
  homepage "$REPO_URL"

  app "bergen.app"

  zap trash: [
    "~/Library/Application Support/bergen",
    "~/Library/Caches/bergen",
    "~/Library/Preferences/com.${REPO_OWNER}.bergen.plist",
    "~/Library/Saved Application State/com.${REPO_OWNER}.bergen.savedState"
  ]
end
EOL

# Commit the changes
git add "$CASK_PATH"
git commit -m "Add $APP_NAME $VERSION"

# Push to fork
git push -u origin "$BRANCH_NAME"

# Create a pull request
echo -e "${BLUE}🚀 Creating pull request...${NC}"
gh pr create --repo homebrew/homebrew-cask \
    --title "Add $APP_NAME $VERSION" \
    --body "This PR adds a cask for $APP_NAME version $VERSION. 
    
$APP_NAME is a React Native macOS app for Markdown viewing.

**App homepage:** $REPO_URL" \
    --base master \
    --head "$REPO_OWNER:$BRANCH_NAME"

echo -e "${GREEN}✅ Pull request created successfully!${NC}"
echo -e "${BLUE}🌎 Check your GitHub profile for the PR link${NC}"
echo -e "${YELLOW}⚠️  Note: The PR will be reviewed by Homebrew maintainers before merging.${NC}"
echo -e "${YELLOW}⚠️  This process can take a few days to a few weeks.${NC}"

cd .. 