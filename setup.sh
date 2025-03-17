#!/bin/bash

# Termux XFCE Desktop Setup with macOS Themes
set -e

SCRIPT_CONTENT='#!/bin/bash

# Main Installation Script
set -e

# Configuration
THEME_NAME="WhiteSur-dark"
ICON_NAME="WhiteSur"
CURSOR_NAME="WhiteSur-cursors"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"

echo -e "\n\033[1;32mStarting system update...\033[0m"
pkg update -y && pkg upgrade -y

echo -e "\n\033[1;32mInstalling core dependencies...\033[0m"
pkg install -y coreutils git wget unzip

echo -e "\n\033[1;32mSetting up storage...\033[0m"
termux-setup-storage

echo -e "\n\033[1;32mInstalling X11 repository...\033[0m"
pkg install x11-repo -y

echo -e "\n\033[1;32mInstalling Termux-X11...\033[0m"
pkg install termux-x11-nightly -y

echo -e "\n\033[1;32mSetting up PulseAudio...\033[0m"
pkg install pulseaudio -y

echo -e "\n\033[1;32mAdding TUR repository...\033[0m"
pkg install tur-repo -y
pkg update -y

echo -e "\n\033[1;32mInstalling XFCE components...\033[0m"
pkg install -y xwayland xfce4 xfce4-terminal xfce4-taskmanager \
    xfce4-whiskermenu-plugin xfce4-clipman-plugin xfce4-appmenu-plugin \
    firefox code-oss chromium

echo -e "\n\033[1;32mInstalling macOS Themes...\033[0m"

# Install WhiteSur Theme
echo "Installing WhiteSur Theme Suite..."
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git 2>/dev/null || true
WhiteSur-gtk-theme/install.sh -d $PREFIX/share/themes -c dark -t all -N glassy
rm -rf WhiteSur-gtk-theme

# Install MacOS Icon Theme
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git 2>/dev/null || true
WhiteSur-icon-theme/install.sh -d $PREFIX/share/icons
rm -rf WhiteSur-icon-theme

# Install MacOS Cursors
git clone https://github.com/vinceliuice/WhiteSur-cursors.git 2>/dev/null || true
mkdir -p $PREFIX/share/icons
cp -r WhiteSur-cursors/dist/* $PREFIX/share/icons/
rm -rf WhiteSur-cursors

# Alternative Mojave Theme
git clone https://github.com/vinceliuice/McMojave-circle.git 2>/dev/null || true
mkdir -p $PREFIX/share/icons/McMojave-circle
cp -r McMojave-circle/* $PREFIX/share/icons/McMojave-circle/
rm -rf McMojave-circle

echo -e "\n\033[1;32mSetting up macOS Wallpapers...\033[0m"
mkdir -p $WALLPAPER_DIR

declare -A WALLPAPERS=(
    ["macos-sonoma"]="https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    ["macos-ventura"]="https://4kwallpapers.com/images/wallpapers/macos-ventura-5120x2880-11736.jpg"
    ["macos-monterey"]="https://4kwallpapers.com/images/wallpapers/macos-monterey-5120x2880-11235.jpg"
)

for name in "${!WALLPAPERS[@]}"; do
    wget -q -O $WALLPAPER_DIR/"${name}.jpg" "${WALLPAPERS[$name]}"
done

echo -e "\n\033[1;32mConfiguring Desktop...\033[0m"
xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME"
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_NAME"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "$CURSOR_NAME"
xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME"

# Set default Sonoma wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER_DIR/macos-sonoma.jpg"

echo -e "\n\033[1;32mFinalizing setup...\033[0m"
pkg autoremove -y
rm -rf *.zip *.tar.gz

echo -e "\n\033[1;32mCreating startup script...\033[0m"
cat > ~/.xfce4-session << "EOF"
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
xfce4-session
EOF
chmod +x ~/.xfce4-session

echo -e "\n\033[1;32mInstallation complete!\033[0m"

cat << "EOF"

To start XFCE Desktop:
1. Install Termux:X11 from F-Droid
2. Run these commands:
   termux-x11 :0 &
   sleep 2
   ./.xfce4-session

Theme Options:
- WhiteSur-dark (default)
- McMojave-circle (alternative icons)
- Change via: xfce4-appearance-settings

Wallpaper location: $PREFIX/share/backgrounds/xfce
EOF
'

# Create installer
echo -e "\033[1;36mCreating installer...\033[0m"
[ -f ~/setup.sh ] && mv ~/setup.sh ~/setup.sh.bak
cat <<EOF > ~/setup.sh
$SCRIPT_CONTENT
EOF
chmod +x ~/setup.sh

# Create shortcut
mkdir -p ~/bin
ln -sf ~/setup.sh ~/bin/setup

echo -e "\n\033[1;32mSetup complete! Run with:\033[0m"
echo -e "  ./setup.sh  or  setup\n"

read -p "Start installation now? (y/N) " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && exec ~/setup.sh
