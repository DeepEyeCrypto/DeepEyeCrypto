#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

set -e

# Common directory for themes and icons
COMMON_DIR="$PREFIX/share/themes_and_icons"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure required commands are available
for cmd in wget tar xz; do
    if ! command_exists "$cmd"; then
        echo -e "${RED}Error: $cmd is not installed.${NC}" >&2
        exit 1
    fi
done

# Install required packages
echo -e "${BLUE}Installing required packages...${NC}"
pkg install -y wget tar xz-utils

# Create common directory
echo -e "${YELLOW}Creating common directory...${NC}"
mkdir -p $COMMON_DIR

# Download and install icons
echo -e "${GREEN}Installing icons...${NC}"
ICON_URL="https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/6791955fe41d761d997a257496963514b01e7bea/01-WhiteSur.tar.xz"
wget -q $ICON_URL -O $COMMON_DIR/WhiteSur.tar.xz
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error downloading icons.${NC}" >&2
    exit 1
fi
tar -xf $COMMON_DIR/WhiteSur.tar.xz -C $COMMON_DIR
rm $COMMON_DIR/WhiteSur.tar.xz

# Download and install themes
echo -e "${GREEN}Installing themes...${NC}"
THEME_URLS=(
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark-solid-nord.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Light.tar.xz"
)

for url in "${THEME_URLS[@]}"; do
    filename=$(basename "$url")
    wget -q "$url" -O $COMMON_DIR/"$filename"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error downloading theme $filename.${NC}" >&2
        exit 1
    fi
    tar -xf $COMMON_DIR/"$filename" -C $COMMON_DIR
    rm $COMMON_DIR/"$filename"
done

# Download wallpapers
echo -e "${GREEN}Downloading wallpapers...${NC}"
WALLPAPER_URLS=(
    "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/Monterey-dark.jpg"
    "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/WhiteSur-dark.jpg"
    "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/Ventura-dark.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
    "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
)

for wp_url in "${WALLPAPER_URLS[@]}"; do
    wget -q --show-progress "$wp_url" -P $PREFIX/share/backgrounds/xfce/
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error downloading wallpaper $wp_url.${NC}" >&2
        exit 1
    fi
done

echo -e "${BLUE}Installation complete!${NC}"
echo -e "${GREEN}To apply changes:${NC}"
echo -e "1. Open XFCE Settings Manager"
echo -e "2. Choose 'Appearance' to select themes"
echo -e "3. Use 'Window Manager' to select window theme"
echo -e "4. Set wallpaper from $PREFIX/share/backgrounds/xfce/"
