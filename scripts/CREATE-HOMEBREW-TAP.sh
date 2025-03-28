#!/bin/bash

# Exit on error
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Creating your own Homebrew tap for Bergen...${NC}"

# Get GitHub username
REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's|^git@github.com:|https://github.com/|')
REPO_OWNER=$(echo $REPO_URL | sed -E 's|https://github.com/([^/]+)/.*|\1|')

echo -e "${BLUE}Using GitHub username: ${REPO_OWNER}${NC}"

# Create the repository structure
HOMEBREW_TAP_DIR="homebrew-bergen"
CASKS_DIR="${HOMEBREW_TAP_DIR}/Casks"

echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "${CASKS_DIR}"

# Copy the cask file
CASK_FILE="homebrew-cask/Casks/b/bergen.rb"
if [ -f "${CASK_FILE}" ]; then
    echo -e "${YELLOW}Copying cask file...${NC}"
    cp "${CASK_FILE}" "${CASKS_DIR}/bergen.rb"
else
    echo -e "${RED}Error: Cask file not found at ${CASK_FILE}${NC}"
    echo -e "${YELLOW}Creating a new cask file instead...${NC}"
    
    # Get current version from package.json
    VERSION=$(node -p "require('../package.json').version")
    
    # Calculate SHA256 of the latest zip file
    ZIP_NAME="bergen-macos-v${VERSION}.zip"
    if [ -f "${ZIP_NAME}" ]; then
        SHA256=$(shasum -a 256 "${ZIP_NAME}" | awk '{print $1}')
    else
        echo -e "${RED}Error: ZIP file ${ZIP_NAME} not found. Please run build-macos.sh first.${NC}"
        exit 1
    fi
    
    # Create the cask file
    cat > "${CASKS_DIR}/bergen.rb" << EOL
cask "bergen" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/${REPO_OWNER}/bergen/releases/download/v#{version}/bergen-macos-v${VERSION}.zip"
  name "Bergen"
  desc "Lightweight markdown reader"
  homepage "https://github.com/${REPO_OWNER}/bergen"
  
  depends_on macos: ">= :big_sur"

  app "bergen.app"

  zap trash: [
    "~/Library/Application Support/bergen",
    "~/Library/Caches/bergen",
    "~/Library/Preferences/com.zendo.bergen.plist",
    "~/Library/Saved Application State/com.zendo.bergen.savedState",
  ]
end
EOL
fi

# Create README.md
cat > "${HOMEBREW_TAP_DIR}/README.md" << EOL
# Homebrew Bergen Tap

This is a custom [Homebrew Tap](https://docs.brew.sh/Taps) for Bergen, a lightweight markdown reader for macOS.

## Installation

\`\`\`bash
# Add this tap
brew tap ${REPO_OWNER}/bergen

# Install Bergen
brew install ${REPO_OWNER}/bergen/bergen
\`\`\`

## About Bergen

Bergen is a beautiful, minimal Markdown reader for macOS .

For more information, visit the [Bergen repository](https://github.com/${REPO_OWNER}/bergen).
EOL

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed. Please install it with 'brew install gh' and login.${NC}"
    echo -e "${YELLOW}You'll need to manually create and push the repository:${NC}"
    echo "1. Go to https://github.com/new"
    echo "2. Create a repository named 'homebrew-bergen'"
    echo "3. Run these commands:"
    echo "   cd ${HOMEBREW_TAP_DIR}"
    echo "   git init"
    echo "   git add ."
    echo "   git commit -m 'Initial commit with bergen cask'"
    echo "   git remote add origin https://github.com/${REPO_OWNER}/homebrew-bergen.git"
    echo "   git push -u origin main"
    exit 0
fi

# Initialize git repository
echo -e "${YELLOW}Initializing git repository...${NC}"
cd "${HOMEBREW_TAP_DIR}"
git init
git add .
git commit -m "Initial commit with bergen cask"

# Create GitHub repository and push
echo -e "${YELLOW}Creating GitHub repository...${NC}"
gh repo create "${REPO_OWNER}/homebrew-bergen" --public --description "Homebrew tap for Bergen markdown reader" --source=. --push

echo -e "${GREEN}✅ Homebrew tap created successfully!${NC}"
echo -e "${BLUE}Users can now install Bergen with:${NC}"
echo -e "${GREEN}brew tap ${REPO_OWNER}/bergen${NC}"
echo -e "${GREEN}brew install ${REPO_OWNER}/bergen/bergen${NC}"

cd ..