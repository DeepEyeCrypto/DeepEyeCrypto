#!/bin/bash

# Color variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Configuration
THEME_DIR="$HOME/.themes"
ICON_DIR="$HOME/.icons"
WALLPAPER_DIR="$HOME/.local/share/backgrounds/xfce"
TEMP_DIR="/tmp/xfce-install"
DEFAULT_WALLPAPER="https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"

# Exit on error
set -e

# Helper functions
error_exit() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

status_msg() {
    echo -e "${CYAN}[STATUS] $1${NC}"
}

success_msg() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Create directories
mkdir -p {$THEME_DIR,$ICON_DIR,$WALLPAPER_DIR,$TEMP_DIR}

# Main installation
echo -e "${GREEN}=== Starting XFCE Desktop Environment Installation ===${NC}"

# System update
status_msg "Updating packages..."
pkg update -y && pkg upgrade -y || error_exit "Failed to update packages"

# Install core components
status_msg "Installing XFCE and dependencies..."
termux-setup-storage
pkg install -y x11-repo termux-x11-nightly pulseaudio xfce4 \
    git wget meson sassc gnome-themes-extra || error_exit "Core installation failed"

# Install applications
status_msg "Installing additional software..."
pkg install -y tur-repo firefox code-oss chromium || error_exit "App installation failed"

# Install WhiteSur Theme
status_msg "Installing WhiteSur Theme Suite..."
(
    cd $TEMP_DIR
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git || error_exit "Theme clone failed"
    cd WhiteSur-gtk-theme
    ./install.sh -t all -c dark -C -N -o --xdg-home || error_exit "Theme install failed"
) || error_exit

# Install WhiteSur Icons
status_msg "Installing WhiteSur Icons..."
(
    cd $TEMP_DIR
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git || error_exit "Icon clone failed"
    cd WhiteSur-icon-theme
    ./install.sh --black --xdg-home || error_exit "Icon install failed"
) || error_exit

# Install Wallpapers
status_msg "Setting up wallpapers..."
(
    cd $TEMP_DIR
    git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git || error_exit "Wallpaper clone failed"
    cd WhiteSur-wallpapers
    ./install.sh --xdg-home || error_exit "Wallpaper install failed"
    
    # Additional wallpapers
    declare -a EXTRA_WALLPAPERS=(
        "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
        "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
        "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
        "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
    )
    
    for url in "${EXTRA_WALLPAPERS[@]}"; do
        wget -q --show-progress -P $WALLPAPER_DIR "$url" || error_exit "Failed to download $url"
    done
) || error_exit

# Configure XFCE
status_msg "Configuring desktop environment..."
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark" || error_exit "Theme config failed"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark" || error_exit "Icon config failed"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-dark" || error_exit "WM theme config failed"
wget -qO $WALLPAPER_DIR/default.jpg $DEFAULT_WALLPAPER || error_exit "Default wallpaper download failed"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_DIR/default.jpg"

# Install DeepEyeCrypto
status_msg "Installing DeepEyeCrypto..."
(
    cd ~
    wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/main/DeepEyeCrypto.sh || error_exit "Download failed"
    chmod +x DeepEyeCrypto.sh
    bash DeepEyeCrypto.sh
) || error_exit

# Cleanup
status_msg "Cleaning up..."
rm -rf $TEMP_DIR

# Final instructions
success_msg "Installation completed successfully!"
echo -e "${YELLOW}To start XFCE:"
echo -e "1. Run: termux-x11 &"
echo -e "2. Then run: xfce4-session${NC}"
