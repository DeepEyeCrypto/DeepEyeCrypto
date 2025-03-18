#!/bin/bash

# Termux XFCE Installation Script
# Version: 1.1
# Improved error handling and debugging

# Configuration
INSTALL_URL="https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/install_xfce_native.sh"
SCRIPT_NAME="install_xfce_native.sh"
TMP_DIR="${HOME}/termux_xfce_install"
LOG_FILE="${TMP_DIR}/installation.log"

# Text formatting
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# Initialize logging
init_logging() {
    mkdir -p "${TMP_DIR}"
    exec > >(tee -a "${LOG_FILE}") 2>&1
}

# Error handling
handle_error() {
    echo -e "${RED}${BOLD}Error detected:${NC}"
    echo -e "• Line: ${BASH_LINENO[0]}"
    echo -e "• Command: ${BASH_COMMAND}"
    echo -e "${YELLOW}Check log file: ${LOG_FILE}${NC}"
    cleanup
    exit 1
}

# Cleanup resources
cleanup() {
    echo -e "${CYAN}Cleaning up...${NC}"
    rm -rf "${TMP_DIR}/${SCRIPT_NAME}"
    echo -e "${GREEN}Cleanup completed!${NC}"
}

# Check requirements
check_requirements() {
    echo -e "${CYAN}Checking system requirements...${NC}"
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl is required but not found!${NC}"
        echo -e "Install with: ${BOLD}pkg install curl${NC}"
        exit 1
    fi

    # Check storage permission
    if [ ! -w "${PWD}" ]; then
        echo -e "${RED}Storage permission denied!${NC}"
        echo -e "Grant storage access with: ${BOLD}termux-setup-storage${NC}"
        exit 1
    fi

    echo -e "${GREEN}All requirements satisfied!${NC}"
}

# Download installer
download_installer() {
    echo -e "${CYAN}Downloading installation script...${NC}"
    if ! curl -sSLf "${INSTALL_URL}" -o "${TMP_DIR}/${SCRIPT_NAME}"; then
        echo -e "${RED}Failed to download installer!${NC}"
        echo -e "Check:"
        echo -e "1. Internet connection"
        echo -e "2. URL availability: ${INSTALL_URL}"
        exit 1
    fi
    chmod +x "${TMP_DIR}/${SCRIPT_NAME}"
}

# Main installation
run_installation() {
    echo -e "${CYAN}Starting installation...${NC}"
    cd "${TMP_DIR}" || exit 1
    "./${SCRIPT_NAME}" || {
        echo -e "${RED}Installation script failed!${NC}"
        exit 1
    }
}

# Main execution flow
main() {
    init_logging
    trap handle_error ERR
    trap 'echo -e "\n${RED}Installation interrupted!${NC}"; cleanup; exit 1' SIGINT

    check_requirements
    download_installer
    run_installation
    cleanup
    
    echo -e "\n${GREEN}${BOLD}Successfully completed installation!${NC}"
    echo -e "Log file preserved at: ${LOG_FILE}"
}

# Start main process
main
