#!/bin/bash

# Exit on error
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the root directory of the project
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${BLUE}Updating Homebrew tap for Bergen...${NC}"

# Get GitHub username
REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's|^git@github.com:|https://github.com/|')
REPO_OWNER=$(echo $REPO_URL | sed -E 's|https://github.com/([^/]+)/.*|\1|')

echo -e "${BLUE}Using GitHub username: ${REPO_OWNER}${NC}"

# Get current version from package.json (using absolute path)
VERSION=$(node -p "require('${PROJECT_ROOT}/package.json').version")
echo -e "${YELLOW}Updating to version: ${VERSION}${NC}"

# Calculate SHA256 of the latest zip file
ZIP_NAME="bergen-macos-v${VERSION}.zip"
if [ ! -f "${PROJECT_ROOT}/${ZIP_NAME}" ]; then
    echo -e "${RED}Error: ZIP file ${ZIP_NAME} not found. Please run yarn build first.${NC}"
    exit 1
fi

SHA256=$(shasum -a 256 "${PROJECT_ROOT}/${ZIP_NAME}" | awk '{print $1}')

# Clone or pull the tap repository
TAP_DIR="${PROJECT_ROOT}/homebrew-bergen"
if [ -d "${TAP_DIR}" ]; then
    echo -e "${YELLOW}Updating existing tap repository...${NC}"
    cd "${TAP_DIR}"
    # Try to determine the default branch
    DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    if [ -z "${DEFAULT_BRANCH}" ]; then
        # Fallback to checking both main and master
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            DEFAULT_BRANCH="main"
        elif git show-ref --verify --quiet refs/remotes/origin/master; then
            DEFAULT_BRANCH="master"
        else
            echo -e "${RED}Error: Could not determine default branch. Neither 'main' nor 'master' found.${NC}"
            exit 1
        fi
    fi
    git pull origin "${DEFAULT_BRANCH}"
else
    echo -e "${YELLOW}Cloning tap repository...${NC}"
    git clone "https://github.com/${REPO_OWNER}/homebrew-bergen.git" "${TAP_DIR}"
    cd "${TAP_DIR}"
    # Determine default branch after clone
    DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

# Update the cask file
echo -e "${YELLOW}Updating cask file...${NC}"
mkdir -p "Casks"
cat > "Casks/bergen.rb" << EOL
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

# Commit and push changes
echo -e "${YELLOW}Committing and pushing changes...${NC}"
git add Casks/bergen.rb
git commit -m "Update bergen to version ${VERSION}"
git push origin "${DEFAULT_BRANCH}"

echo -e "${GREEN}✅ Homebrew tap updated successfully to version ${VERSION}!${NC}"
echo -e "${BLUE}Users can update Bergen with:${NC}"
echo -e "${GREEN}brew update${NC}"
echo -e "${GREEN}brew upgrade bergen${NC}"

cd "${PROJECT_ROOT}" 