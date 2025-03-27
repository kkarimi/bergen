#!/bin/bash

# Exit on error
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for certificate file
CERT_PATH="./cert/development.cer"
if [ ! -f "$CERT_PATH" ]; then
    echo -e "${RED}Certificate not found at $CERT_PATH${NC}"
    echo -e "${YELLOW}Please place your developer certificate in the cert directory${NC}"
    exit 1
fi

echo -e "${BLUE}Installing developer certificate...${NC}"

# Get certificate info
CERT_SHA1=$(openssl x509 -in "$CERT_PATH" -inform DER -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
CERT_CN=$(openssl x509 -in "$CERT_PATH" -inform DER -noout -subject | sed -n 's/.*CN=\([^,]*\).*/\1/p')

echo -e "${BLUE}Certificate SHA1: $CERT_SHA1${NC}"
echo -e "${BLUE}Certificate Common Name: $CERT_CN${NC}"

# Check if certificate is already in keychain
if security find-certificate -a -c "$CERT_CN" -Z | grep -q "$CERT_SHA1"; then
    echo -e "${GREEN}Certificate is already installed in keychain${NC}"
else
    echo -e "${YELLOW}Installing certificate to keychain...${NC}"
    
    # Import certificate to keychain
    security import "$CERT_PATH" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificate installed successfully${NC}"
    else
        echo -e "${RED}Failed to install certificate${NC}"
        exit 1
    fi
fi

# Import private key if it exists
PRIVATE_KEY_PATH="./cert/private_key.p12"
if [ -f "$PRIVATE_KEY_PATH" ]; then
    echo -e "${BLUE}Found private key at $PRIVATE_KEY_PATH${NC}"
    echo -e "${YELLOW}Installing private key to keychain...${NC}"
    
    # Prompt for password if needed
    read -sp "Enter private key password (press enter if none): " PRIVATE_KEY_PASSWORD
    echo ""
    
    if [ -z "$PRIVATE_KEY_PASSWORD" ]; then
        security import "$PRIVATE_KEY_PATH" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign
    else
        security import "$PRIVATE_KEY_PATH" -k ~/Library/Keychains/login.keychain-db -P "$PRIVATE_KEY_PASSWORD" -T /usr/bin/codesign
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Private key installed successfully${NC}"
    else
        echo -e "${RED}Failed to install private key${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}No private key found at $PRIVATE_KEY_PATH${NC}"
    echo -e "${YELLOW}If you have a private key, please save it as cert/private_key.p12${NC}"
fi

# Update .env file with certificate info
if [ -f .env ]; then
    echo -e "${BLUE}Updating .env file with certificate information...${NC}"
    
    # Check if APPLE_DEVELOPER_ID is already set
    if grep -q "APPLE_DEVELOPER_ID=" .env; then
        # Update existing APPLE_DEVELOPER_ID
        sed -i '' "s|APPLE_DEVELOPER_ID=.*|APPLE_DEVELOPER_ID=\"$CERT_CN\"|g" .env
    else
        # Add APPLE_DEVELOPER_ID
        echo "APPLE_DEVELOPER_ID=\"$CERT_CN\"" >> .env
    fi
    
    echo -e "${GREEN}Updated .env file with certificate information${NC}"
else
    echo -e "${YELLOW}No .env file found${NC}"
    echo -e "${YELLOW}Creating .env file with certificate information...${NC}"
    
    # Create .env file
    cp .env.example .env
    
    # Update APPLE_DEVELOPER_ID
    sed -i '' "s|APPLE_DEVELOPER_ID=.*|APPLE_DEVELOPER_ID=\"$CERT_CN\"|g" .env
    
    echo -e "${GREEN}Created .env file with certificate information${NC}"
fi

echo -e "${GREEN}✅ Certificate installation complete${NC}"
echo -e "${BLUE}You can now build your app with:${NC}"
echo -e "${GREEN}./build-macos.sh${NC}"