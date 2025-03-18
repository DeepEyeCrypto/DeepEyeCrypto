#!/bin/bash

# Automated installation script for XFCE in Termux
# Original command reference: 
# curl -sL https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/install_xfce_native.sh -o install.sh && bash install.sh

set -e  # Exit script immediately if any command fails

# Color codes for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

# Error handling function
handle_error() {
    echo -e "${RED}Error occurred! Installation failed.${NC}" >&2
    exit 1
}

trap 'handle_error' ERR

# Check for curl
echo -e "${YELLOW}Checking for required dependencies...${NC}"
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed.${NC}"
    echo "Install curl using:"
    echo "pkg install curl"
    exit 1
fi

# Download installation script
echo -e "${YELLOW}Downloading XFCE installation script...${NC}"
if ! curl -sSL --fail https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/install_xfce_native.sh -o install.sh; then
    echo -e "${RED}Error: Failed to download installation script!${NC}"
    echo "Please check your internet connection and try again."
    exit 1
fi

# Verify downloaded file
if [ ! -s install.sh ]; then
    echo -e "${RED}Error: Downloaded file is empty or invalid!${NC}"
    exit 1
fi

# Execute installation
echo -e "${GREEN}Starting XFCE installation...${NC}"
chmod +x install.sh
bash install.sh

echo -e "${GREEN}Installation process completed successfully!${NC}"
