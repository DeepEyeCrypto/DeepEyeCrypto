#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure required commands are available
for cmd in wget tar xz; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# Install required packages
echo "Installing required packages..."
pkg install -y wget tar xz-utils

# Create directories
echo "Creating directories..."
mkdir -p $PREFIX/share/.icons
mkdir -p $PREFIX/share/.themes
mkdir -p $PREFIX/share/backgrounds/xfce

# Download and install icons
echo "Installing icons..."
ICON_URL="https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/6791955fe41d761d997a257496963514b01e7bea/01-WhiteSur.tar.xz"
wget -q $ICON_URL -O $PREFIX/share/.icons/WhiteSur.tar.xz
if [[ $? -ne 0 ]]; then
    echo "Error downloading icons." >&2
    exit 1
fi
tar -xf $PREFIX/share/.icons/WhiteSur.tar.xz -C $PREFIX/share/.icons/
rm $PREFIX/share/.icons/WhiteSur.tar.xz

# Download and install themes
echo "Installing themes..."
THEME_URLS=(
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark-solid-nord.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Light.tar.xz"
)

for url in "${THEME_URLS[@]}"; do
    filename=$(basename "$url")
    wget -q "$url" -O $PREFIX/share/.themes/"$filename"
    if [[ $? -ne 0 ]]; then
        echo "Error downloading theme $filename." >&2
        exit 1
    fi
    tar -xf $PREFIX/share/.themes/"$filename" -C $PREFIX/share/.themes/
    rm $PREFIX/share/.themes/"$filename"
done

# Download wallpapers
echo "Downloading wallpapers..."
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
        echo "Error downloading wallpaper $wp_url." >&2
        exit 1
    fi
done

# Clean up
echo "Cleaning up..."
apt autoremove -y

echo "Installation complete!"
echo "To apply changes:"
echo "1. Open XFCE Settings Manager"
echo "2. Choose 'Appearance' to select themes"
echo "3. Use 'Window Manager' to select window theme"
echo "4. Set wallpaper from $PREFIX/share/backgrounds/xfce/"
