#!/bin/bash

# Script Name: termux_x11_setup.sh
# Description: Termux-X11 ke liye optimized Debian + XFCE4 setup with GPU acceleration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if Termux is installed
if ! command -v pkg &> /dev/null; then
    echo -e "${RED}Termux nahi mila! Please Termux install karein.${NC}"
    exit 1
fi

echo -e "${GREEN}Termux-X11 aur Debian setup start ho raha hai...${NC}"

# Update Termux and install required packages
pkg update -y && pkg upgrade -y
pkg install x11-repo -y
pkg install termux-x11-nightly pulseaudio proot-distro wget git -y

# Install Termux-X11 APK if not already installed
if ! pm list packages | grep -q com.termux.x11; then
    echo -e "${GREEN}Termux-X11 APK download aur install ho raha hai...${NC}"
    wget https://github.com/termux/termux-x11/releases/download/nightly/app-universal-debug.apk
    termux-open app-universal-debug.apk
    echo -e "${RED}Termux-X11 APK install karein aur script phir se chalayein.${NC}"
    exit 0
fi

# Install Debian proot-distro
echo -e "${GREEN}Debian proot-distro install ho raha hai...${NC}"
proot-distro install debian

# Setup XFCE4 and GPU acceleration in Debian
echo -e "${GREEN}Debian mein XFCE4 aur GPU acceleration setup ho raha hai...${NC}"
proot-distro login debian --shared-tmp -- bash -c "
    apt update && apt upgrade -y
    apt install xfce4 xfce4-terminal -y
    apt install mesa-zink virglrenderer-mesa-zink vulkan-loader-android -y
    echo 'export GALLIUM_DRIVER=virpipe' >> ~/.bashrc
    echo 'export MESA_GL_VERSION_OVERRIDE=4.0' >> ~/.bashrc
"

# Create a startup script for Termux-X11
echo -e "${GREEN}Termux-X11 startup script create ho raha hai...${NC}"
cat > ~/start_x11.sh << EOL
#!/bin/bash
# Start Termux-X11 and XFCE4 with GPU acceleration
export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
pulseaudio --start
termux-x11 :0 -xstartup "dbus-launch --exit-with-session xfce4-session" &
proot-distro login debian --shared-tmp -- bash -c "startxfce4 &"
EOL

chmod +x ~/start_x11.sh

# Enable storage permission
termux-setup-storage

# Instructions for user
echo -e "${GREEN}Setup complete! Instructions:${NC}"
echo -e "1. Termux-X11 app kholein."
echo -e "2. Terminal mein yeh command chalayein: ${GREEN}~/start_x11.sh${NC}"
echo -e "3. Agar display issues hain, to Termux-X11 app ke Preferences mein resolution ya DPI adjust karein."
echo -e "4. Qualcomm devices ke liye Zink use karne ke liye, ~/.bashrc mein 'GALLIUM_DRIVER=zink' set karein."

exit 0
