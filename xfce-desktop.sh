#!/bin/bash

# Termux XFCE Installation Script
# Version: 1.0
# Author: Your Name
# Description: Automated installation of XFCE in Termux

# Set variables
INSTALL_URL="https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/install_xfce_native.sh"
SCRIPT_NAME="install.sh"
TMP_DIR="$HOME/.tmp_install_xfce"

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Error handling
set -e
trap 'catch_error $? $LINENO' ERR

catch_error() {
    echo -e "${RED}Error $1 occurred on line $2${NC}"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    rm -rf "$TMP_DIR/$SCRIPT_NAME"
    echo -e "${GREEN}Cleanup completed!${NC}"
}

# Check dependencies
check_dependencies() {
    echo -e "${CYAN}Checking dependencies...${NC}"
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl is required but not installed!${NC}"
        echo -e "${YELLOW}Install it with: pkg install curl${NC}"
        exit 1
    fi
    echo -e "${GREEN}All dependencies are satisfied!${NC}"
}

# Main installation function
install_xfce() {
    echo -e "${CYAN}Starting XFCE installation...${NC}"
    
    # Create temporary directory
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    
    # Download installation script
    echo -e "${YELLOW}Downloading installation script...${NC}"
    curl -sSLf "$INSTALL_URL" -o "$SCRIPT_NAME"
    
    # Make script executable
    chmod +x "$SCRIPT_NAME"
    
    # Execute installation script
    echo -e "${CYAN}Running installation script...${NC}"
    bash "$SCRIPT_NAME"
    
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Main execution
main() {
    check_dependencies
    install_xfce
    cleanup
}

# Handle Ctrl+C
trap 'echo -e "\n${RED}Installation interrupted!${NC}"; cleanup; exit 1' SIGINT

# Start main process
main
