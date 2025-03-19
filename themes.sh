#!/data/data/com.termux/files/usr/bin/bash
set -e

# Check if running in Termux
if [ ! -d "$PREFIX" ]; then
    echo "Error: This script must be run in Termux environment"
    exit 1
fi

# Install required packages
echo -e "\e[1;34mInstalling dependencies...\e[0m"
pkg update -y && pkg install -y wget tar xz-utils

# Create directories
echo -e "\e[1;34mCreating directories...\e[0m"
mkdir -p $PREFIX/share/{.icons,.themes,backgrounds/xfce}

# Install icons
echo -e "\e[1;32mInstalling WhiteSur icons...\e[0m"
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/main/01-WhiteSur.tar.xz \
    -O $PREFIX/share/.icons/WhiteSur.tar.xz
tar -xJf $PREFIX/share/.icons/WhiteSur.tar.xz -C $PREFIX/share/.icons/ && \
    rm $PREFIX/share/.icons/WhiteSur.tar.xz

# Install themes
echo -e "\e[1;32mInstalling GTK themes...\e[0m"
theme_urls=(
    "WhiteSur-Dark-solid-nord.tar.xz"
    "WhiteSur-Dark.tar.xz"
    "WhiteSur-Light.tar.xz"
)

for theme in "${theme_urls[@]}"; do
    echo "Downloading $theme..."
    wget -q "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/master/release/$theme" \
        -O $PREFIX/share/.themes/$theme
    tar -xJf $PREFIX/share/.themes/$theme -C $PREFIX/share/.themes/
    rm $PREFIX/share/.themes/$theme
done

# Download wallpapers
echo -e "\e[1;32mDownloading wallpapers...\e[0m"
wallpaper_urls=(
    "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/Monterey-dark.jpg"
    "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/WhiteSur-dark.jpg"
    "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/Ventura-dark.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
    "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
)

for wallpaper in "${wallpaper_urls[@]}"; do
    echo "Downloading $(basename "$wallpaper")..."
    wget -q --show-progress "$wallpaper" -P $PREFIX/share/backgrounds/xfce/
done

# Cleanup
echo -e "\e[1;34mCleaning up...\e[0m"
pkg uninstall -y tar xz-utils
rm -rf $PREFIX/share/.icons/*.tar.xz $PREFIX/share/.themes/*.tar.xz

echo -e "\e[1;36mInstallation complete!\e[0m"
echo -e "\nTo apply changes:"
echo -e "1. Open \e[1;33mXFCE Settings Manager\e[0m"
echo -e "2. Appearance: Select WhiteSur theme variant"
echo -e "3. Window Manager: Choose WhiteSur window style"
echo -e "4. Set wallpaper from $PREFIX/share/backgrounds/xfce/"
