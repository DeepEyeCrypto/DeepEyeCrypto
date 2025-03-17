#!/bin/bash

# Auto-Installer Creator Script (FIXED VERSION)
set -e

# Define script content
SCRIPT_CONTENT='#!/bin/bash

# Termux XFCE Desktop Setup Script
set -e

# Configuration
THEME_NAME="WhiteSur-dark"
ICON_NAME="WhiteSur"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"

echo -e "\n\033[1;32mStarting system update...\033[0m"
pkg update -y && pkg upgrade -y

echo -e "\n\033[1;32mSetting up storage...\033[0m"
termux-setup-storage

echo -e "\n\033[1;32mInstalling X11 repository...\033[0m"
pkg install x11-repo -y

echo -e "\n\033[1;32mInstalling Termux-X11...\033[0m"
pkg install termux-x11-nightly -y

echo -e "\n\033[1;32mSetting up PulseAudio...\033[0m"
pkg install pulseaudio -y

echo -e "\n\033[1;32mAdding TUR repository and updating packages...\033[0m"
pkg install tur-repo -y
pkg update -y

echo -e "\n\033[1;32mInstalling XFCE Desktop Environment, components, and applications...\033[0m"
pkg install -y xwayland xfce4 xfce4-terminal xfce4-taskmanager xfce4-whiskermenu-plugin xfce4-clipman-plugin plank xfce4-appmenu-plugin git wget unzip firefox code-oss chromium -y

echo -e "\n\033[1;32mInstalling WhiteSur Theme Components...\033[0m"
# GTK Theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
WhiteSur-gtk-theme/install.sh -c dark -t all -l -i arch -N glassy --monterey
rm -rf WhiteSur-gtk-theme

# Icon Theme
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
WhiteSur-icon-theme/install.sh -b
rm -rf WhiteSur-icon-theme

# Cursor Theme
git clone https://github.com/vinceliuice/WhiteSur-cursors.git
mkdir -p $PREFIX/share/icons
cp -r WhiteSur-cursors/dist/* $PREFIX/share/icons/
rm -rf WhiteSur-cursors

echo -e "\n\033[1;32mSetting up macOS Wallpapers...\033[0m"
mkdir -p $WALLPAPER_DIR

# Official WhiteSur Wallpapers
git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git
cp WhiteSur-wallpapers/monterey/*.jpg $WALLPAPER_DIR/
rm -rf WhiteSur-wallpapers

# Additional Wallpapers
declare -A EXTRA_WALLPAPERS=(
    ["MacOS-Big-Sur"]="https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    ["MacOS-Fusion"]="https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    ["MacOS-Sonoma-1"]="https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    ["MacOS-Sonoma-2"]="https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
    ["MacOS-Sierra"]="https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
)

for name in "${!EXTRA_WALLPAPERS[@]}"; do
    wget -O $WALLPAPER_DIR/"${name}.jpg" "${EXTRA_WALLPAPERS[$name]}"
done

echo -e "\n\033[1;32mConfiguring XFCE Desktop...\033[0m"
xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME"
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_NAME"
xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME"

DEFAULT_WALLPAPER="$WALLPAPER_DIR/monterey-night.jpg"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$DEFAULT_WALLPAPER"

xfconf-query -c xfce4-panel -p /panels/panel-0/size -s 36
xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=8;x=0;y=0"

echo -e "\n\033[1;32mFinalizing setup...\033[0m"
pkg autoremove -y
rm -rf *.zip *.tar.gz

echo -e "\n\033[1;32mCreating startup script...\033[0m"
cat > ~/.xfce4-session << EOF
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
xfce4-session
EOF
chmod +x ~/.xfce4-session

echo -e "\n\033[1;32mDownloading DeepEyeCrypto setup...\033[0m"
cd ~
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh
chmod +x DeepEyeCrypto.sh

echo -e "\n\033[1;32mInstallation complete! Starting final setup...\033[0m"
bash ~/DeepEyeCrypto.sh

echo -e "\n\033[1;32mAll tasks completed!\033[0m"

cat << EOF

To start XFCE Desktop:
1. Install Termux:X11 from F-Droid
2. Run these commands in order:
   termux-x11 :0 &
   sleep 2
   ./.xfce4-session

Recommended additional packages:
• Firefox: pkg install firefox
• LibreOffice: pkg install libreoffice
• GIMP: pkg install gimp

Customization Tips:
• Right-click panel → Panel → Panel Preferences to modify layout
• Use '\''xfce4-appearance-settings'\'' to adjust theme variants
• Configure Plank dock: right-click dock → Preferences
• Wallpapers available in: $WALLPAPER_DIR
EOF
'

# Create the setup script
echo -e "\033[1;36mCreating installation script...\033[0m"
[ -f ~/setup.sh ] && mv ~/setup.sh ~/setup.sh.bak

cat <<EOF > ~/setup.sh
$SCRIPT_CONTENT
EOF

chmod +x ~/setup.sh

# Create shortcut
echo -e "\033[1;36mCreating shortcut...\033[0m"
mkdir -p ~/bin
ln -sf ~/setup.sh ~/bin/setup

echo -e "\n\033[1;32mAutomation setup complete!\033[0m"
echo -e "You can now run:\n\n\033[1m./setup.sh\033[0m \nor \033[1msetup\033[0m\n"

# Start confirmation
read -p "Start installation now? (y/N) " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && exec ~/setup.sh
