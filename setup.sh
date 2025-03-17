#!/bin/bash

# Auto-Installer Creator Script (FIXED VERSION)
set -e

# Define script content
SCRIPT_CONTENT='#!/data/data/com.termux/files/usr/bin/bash
# Xfce4 + Openbox Theming Setup for Termux

# Update packages and install requirements
pkg update -y && pkg upgrade -y
pkg install -y x11-repo
pkg install -y termux-x11-nightly openbox xfce4 xfce4-terminal xfce4-panel xfce4-settings thunar lxappearance wget git

# Setup directories
mkdir -p ~/.themes ~/.icons ~/.config/openbox

# Download and install Openbox theme
wget https://raw.githubusercontent.com/openbox-themes-collection/openbox-themes/master/Obsidian-Orange/openbox-3/themerc
mkdir -p ~/.themes/Obsidian-Orange/openbox-3
mv themerc ~/.themes/Obsidian-Orange/openbox-3/

# Create Openbox configuration files
cat > ~/.config/openbox/rc.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Obsidian-Orange</name>
  </theme>
  <keyboard>
    <keybind key="W-t">
      <action name="Execute">
        <command>xfce4-terminal</command>
      </action>
    </keybind>
    <keybind key="W-w">
      <action name="Execute">
        <command>firefox</command>
      </action>
    </keybind>
  </keyboard>
  <mouse>
    <dragThreshold>8</dragThreshold>
  </mouse>
</openbox_config>
EOF

cat > ~/.config/openbox/autostart <<EOF
xfce4-panel &
xfce4-power-manager &
xfsettingsd &
tint2 &
EOF

# Set Openbox as default WM for Xfce
xfconf-query -c xfce4-session -p /sessions/Failsafe/Client0_Command -t string -s openbox --create

# Configure GTK themes
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF

echo "Setup complete! Start your desktop with:"
echo "1. Run 'termux-x11'"
echo "2. In another session:"
echo "   export DISPLAY=:0"
echo "   startxfce4"

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

echo -e "\n\033[1;32mInstalling XFCE Desktop Environment...\033[0m"
pkg install xfce4 -y

echo -e "\n\033[1;32mAdding TUR repository...\033[0m"
pkg install tur-repo -y

echo -e "\n\033[1;32mInstalling applications...\033[0m"
pkg install firefox code-oss chromium git wget -y

echo -e "\n\033[1;32mDownloading DeepEyeCrypto setup...\033[0m"
cd ~
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh
chmod +x DeepEyeCrypto.sh

echo -e "\n\033[1;32mInstallation complete! Starting final setup...\033[0m"
bash ~/DeepEyeCrypto.sh

echo -e "\n\033[1;32mAll tasks completed!\033[0m"

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
