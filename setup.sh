#!/bin/bash

# Auto-Installer Creator Script (FIXED VERSION)
set -e

# Define script content
SCRIPT_CONTENT='#!/bin/bash

# Termux XFCE Desktop Setup Script
set -e

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
[[ $REPLY =~ ^[Yy]$ ]] && exec ./setup.sh
