#!/bin/bash

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Configurations
THEME_NAME="WhiteSur-dark"
THEME_DIR="$HOME/.themes"
ICON_DIR="$HOME/.icons"
WALLPAPER_DIR="$HOME/.local/share/backgrounds/xfce"
TEMP_DIR="/tmp/xfce-setup"

# Exit on error
set -e

# Helper functions
print_status() {
    echo -e "${CYAN}[+]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

# Phase 1: XFCE Installation
install_xfce() {
    print_status "Starting XFCE installation"
    
    print_status "Updating packages"
    pkg update -y && pkg upgrade -y || print_error "Failed to update packages"
    
    print_status "Setting up storage"
    termux-setup-storage
    
    print_status "Installing core components"
    pkg install -y x11-repo termux-x11-nightly pulseaudio xfce4 \
    tur-repo firefox code-oss chromium git wget || print_error "Core installation failed"
    
    print_success "XFCE installed successfully"
}

# Phase 2: Theming
apply_theme() {
    print_status "Starting theming process"
    
    print_status "Installing theme dependencies"
    pkg install -y meson sassc gnome-themes-extra || print_error "Failed to install dependencies"
    
    mkdir -p {$THEME_DIR,$ICON_DIR,$WALLPAPER_DIR,$TEMP_DIR}
    
    # Install GTK Theme
    print_status "Installing WhiteSur GTK Theme"
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme $TEMP_DIR/gtk-theme
    cd $TEMP_DIR/gtk-theme
    ./install.sh -t all -c dark -C -N -o --xdg-home || print_error "Theme install failed"
    
    # Install Icons
    print_status "Installing WhiteSur Icons"
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme $TEMP_DIR/icon-theme
    cd $TEMP_DIR/icon-theme
    ./install.sh --black --xdg-home || print_error "Icon install failed"
    
    # Install Wallpapers
    print_status "Setting up wallpapers"
    git clone https://github.com/vinceliuice/WhiteSur-wallpapers $TEMP_DIR/wallpapers
    cd $TEMP_DIR/wallpapers
    ./install.sh --xdg-home || print_error "Wallpaper install failed"
    
    # Additional Wallpapers
    declare -a EXTRA_WALLPAPERS=(
        "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
        "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
        "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
        "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
        "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
    )
    
    for url in "${EXTRA_WALLPAPERS[@]}"; do
        wget -q --show-progress -P $WALLPAPER_DIR "$url" || print_error "Failed to download wallpaper"
    done
    
    # Configure XFCE
    print_status "Applying theme settings"
    xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME" || print_error "Theme config failed"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "$THEME_NAME" || print_error "Icon config failed"
    xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME" || print_error "WM theme config failed"
    
    # Set default wallpaper
    DEFAULT_WALL="$(ls $WALLPAPER_DIR | grep -m1 'macos')"
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_DIR/$DEFAULT_WALL"
    
    print_success "Theming completed successfully"
}

# Phase 3: Final Setup
finalize() {
    print_status "Running final configurations"
    
    # Install DeepEyeCrypto
    cd ~
    wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/main/DeepEyeCrypto.sh || print_error "Failed to download DeepEyeCrypto"
    chmod +x DeepEyeCrypto.sh
    bash DeepEyeCrypto.sh
    
    # Cleanup
    rm -rf $TEMP_DIR
    
    print_success "All done! Installation complete"
}

# Main execution
install_xfce
apply_theme
finalize

echo -e "\n${GREEN}Start XFCE with:${NC}"
echo -e "  ${YELLOW}termux-x11 &${NC}"
echo -e "  ${YELLOW}xfce4-session${NC}"
