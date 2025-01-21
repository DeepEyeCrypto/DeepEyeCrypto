#!/data/data/com.termux/files/usr/bin/bash

# Initial Setup and Package Installation
termux-setup-storage
pkg update -y && pkg upgrade -y
pkg install -y wget git unzip xfce4-appmenu-plugin ruby

# Install macOS Theme and Icons
mkdir -p /data/data/com.termux/files/home/.themes/ ~/.icons

# macOS Theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git /data/data/com.termux/files/home/.themes/WhiteSur-gtk-theme
cd /data/data/com.termux/files/home/.themes/WhiteSur-gtk-theme
./install.sh

# Extract macOS Themes
cd /data/data/com.termux/files/home/.themes/
for theme in WhiteSur-Dark WhiteSur-Dark-nord WhiteSur-Dark-solid WhiteSur-Dark-solid-nord WhiteSur-Light WhiteSur-Light-nord WhiteSur-Light-solid WhiteSur-Light-solid-nord; do
    tar -xf /data/data/com.termux/files/home/WhiteSur-gtk-theme/release/$theme.tar.xz
done

# macOS Icons
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme
cd ~/WhiteSur-icon-theme
./install.sh

# Set WhiteSur-dark Theme and Icons
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"

# macOS Wallpapers
cd /data/data/com.termux/files/home
wget https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg -O big-sur.jpg
wget https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg -O fusion.jpg
wget https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg -O sonoma1.jpg
wget https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg -O sonoma2.jpg
wget https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg -O high-sierra.jpg

# Set Default Wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s /data/data/com.termux/files/home/big-sur.jpg

# Optional: Add Wallpaper Rotation
while true; do
    for wallpaper in /data/data/com.termux/files/home/*.jpg; do
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$wallpaper"
        sleep 3600  # Change every hour
    done
done &

exit 0
