#!/bin/bash

# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

# Color definitions for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file for debugging
LOG_FILE="$HOME/termux_setup.log"
exec 2>>"$LOG_FILE"

# Temporary directory for setup
TEMP_DIR=$(mktemp -d)

# Centralized logging function
log() {
    local level="$1"
    shift
    echo "[$level] $*" | tee -a "$LOG_FILE"
}

# Function to print status messages
print_status() {
    local status="$1"
    local message="$2"
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}!${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

# Function to clean up on exit
finish() {
    local ret=$?
    if [ $ret -ne 0 ] && [ $ret -ne 130 ]; then
        log "ERROR" "An issue occurred. Please check $LOG_FILE for details."
    fi
    rm -rf "$TEMP_DIR"
}
trap finish EXIT

# Safe execution wrapper
safe_run() {
    "$@" || {
        log "ERROR" "Command failed: $*"
        exit 1
    }
}

# Detect system compatibility
detect_termux() {
    local errors=0
    echo -e "\n${BLUE}System Compatibility Check${NC}\n"

    # Check if running on Android
    if [[ "$(uname -o)" = "Android" ]]; then
        print_status "ok" "Running on Android $(getprop ro.build.version.release)"
    else
        print_status "error" "Not running on Android"
        ((errors++))
    fi

    # Check architecture
    local arch=$(uname -m)
    if [[ "$arch" = "aarch64" ]]; then
        print_status "ok" "Architecture: $arch"
    else
        print_status "error" "Unsupported architecture: $arch (requires aarch64)"
        ((errors++))
    fi

    # Check for Termux PREFIX directory
    if [[ -d "$PREFIX" ]]; then
        print_status "ok" "Termux PREFIX directory found"
    else
        print_status "error" "Termux PREFIX directory not found"
        ((errors++))
    fi

    # Check available storage space
    local free_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ $free_space -ge 4194304 ]]; then
        print_status "ok" "Available storage: ${free_space}KB"
    else
        print_status "warn" "Low storage space: ${free_space}KB (4GB recommended)"
    fi

    # Check RAM
    local total_ram=$(free -m | awk 'NR==2 {print $2}')
    if [[ $total_ram -ge 2048 ]]; then
        print_status "ok" "RAM: ${total_ram}MB"
    else
        print_status "warn" "Low RAM: ${total_ram}MB (2GB recommended)"
    fi

    return $errors
}

# GPU detection and optimization
gpu_check() {
    local gpu_info=$(getprop ro.hardware.egl 2>/dev/null || echo "unknown")
    case $gpu_info in
        *adreno*) log "INFO" "Adreno GPU detected";;
        *mali*) log "INFO" "Mali GPU detected";;
        *powervr*) log "INFO" "PowerVR GPU detected";;
        *intel*) log "INFO" "Intel GPU detected";;
        *) log "ERROR" "Unknown GPU type: $gpu_info"; exit 1;;
    esac
}

# Install dependencies in parallel
install_dependencies() {
    local deps=('wget' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio' 'git')
    printf "%s\n" "${deps[@]}" | xargs -n 1 -P 4 pkg install -y
}

# Main installation function
main() {
    clear
    echo -e "\n${BLUE}XFCE Desktop Installation${NC}\n"

    # Check system compatibility
    if ! detect_termux; then
        log "ERROR" "System requirements not met. Exiting."
        exit 1
    fi

    log "INFO" "Installing dependencies..."
    install_dependencies

    log "INFO" "Setting up GPU optimizations..."
    gpu_check

    log "INFO" "Installing XFCE packages..."
    local xfce_packages=('xfce4' 'xfce4-goodies' 'xfce4-pulseaudio-plugin' 'firefox' 'starship' 'termux-x11-nightly')
    printf "%s\n" "${xfce_packages[@]}" | xargs -n 1 -P 4 pkg install -y

    log "INFO" "Installation complete! Use 'start' to launch your desktop environment."
}

# Start installation
main
