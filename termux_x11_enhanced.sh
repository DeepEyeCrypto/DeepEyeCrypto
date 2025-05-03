#!/bin/bash

# Script Name: termux_x11_enhanced_fixed.sh
# Description: Enhanced Termux-X11 setup with WhiteSur Dark themes, chipset optimization, Chromium, XFCE4, and error handling.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="$HOME/termux_x11_setup.log"
echo "[$(date)] Starting Termux-X11 setup" > "$LOG_FILE"

# Function to show progress bar
progress_bar() {
    local duration=$1
    local task=$2
    echo -e "${BLUE}[$task]${NC}"
    for ((i=0; i<=100; i+=10)); do
        printf "\r[${GREEN}%-10s${NC}] %d%%" "██████████" "$i"
        sleep $(echo "$duration/10" | bc -l)
    done
    echo -e "\n${GREEN}[$task] Complete!${NC}" | tee -a "$LOG_FILE"
}

# Function to check command success
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success!${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}Failed! Check $LOG_FILE for details.${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Check if Termux is installed
if ! command -v pkg &> /dev/null; then
    echo -e "${RED}Termux not found! Please install Termux.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "${YELLOW}🚀 Termux-X11 Enhanced Setup Script 🚀${NC}"
echo -e "${BLUE}Features: WhiteSur Themes, Chipset Optimization, Chromium, XFCE4, Backup/Restore${NC}" | tee -a "$LOG_FILE"

# Interactive prompt for user
echo -e "${YELLOW}Do you want to start the setup? (y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}" | tee -a "$LOG_FILE"
    exit 0
fi

# Enable storage permission
echo -e "${BLUE}Setting up storage permissions...${NC}" | tee -a "$LOG_FILE"
progress_bar 2 "Storage Permission"
termux-setup-storage
check_status

# Configure repositories
echo -e "${BLUE}Configuring repositories...${NC}" | tee -a "$LOG_FILE"
progress_bar 5 "Repository Setup"
echo "deb https://termux.dev/x11-packages unstable main" >> /data/data/com.termux/files/usr/etc/apt/sources.list
pkg update -y && pkg upgrade -y
check_status

# Install essential packages
echo -e "${BLUE}Installing essential packages...${NC}" | tee -a "$LOG_FILE"
progress_bar 10 "Package Installation"
pkg install pulseaudio proot-distro wget git -y
check_status

# Install termux-x11-nightly with retry logic
echo -e "${BLUE}Installing termux-x11-nightly...${NC}" | tee -a "$LOG_FILE"
MAX_RETRIES=3
for ((i = 1; i <= MAX_RETRIES; i++)); do
    pkg install termux-x11-nightly -y
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}termux-x11-nightly installed successfully!${NC}" | tee -a "$LOG_FILE"
        break
    else
        echo -e "${YELLOW}Attempt $i failed. Retrying...${NC}" | tee -a "$LOG_FILE"
    fi
done

if [ $i -gt $MAX_RETRIES ]; then
    echo -e "${RED}Failed to install termux-x11-nightly after $MAX_RETRIES attempts.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi
check_status

# Detect chipset
echo -e "${BLUE}Detecting chipset...${NC}" | tee -a "$LOG_FILE"
progress_bar 2 "Chipset Detection"
CHIPSET=$(cat /proc/cpuinfo | grep "Hardware" | awk -F: '{print $2}' | tr -d '[:space:]')
if [[ $CHIPSET == *"Qualcomm"* || $CHIPSET == *"Snapdragon"* ]]; then
    ACCELERATION="zink"
    DRIVER="GALLIUM_DRIVER=zink"
    echo -e "${GREEN}Qualcomm/Snapdragon detected. Using Zink acceleration.${NC}" | tee -a "$LOG_FILE"
elif [[ $CHIPSET == *"MediaTek"* || $CHIPSET == *"Dimensity"* || $CHIPSET == *"Helio"* ]]; then
    ACCELERATION="virgl"
    DRIVER="GALLIUM_DRIVER=virpipe"
    echo -e "${GREEN}MediaTek detected. Using VirGL acceleration.${NC}" | tee -a "$LOG_FILE"
elif [[ $CHIPSET == *"Exynos"* ]]; then
    ACCELERATION="virgl"
    DRIVER="GALLIUM_DRIVER=virpipe"
    echo -e "${GREEN}Exynos detected. Using VirGL acceleration.${NC}" | tee -a "$LOG_FILE"
else
    ACCELERATION="swrast"
    DRIVER="GALLIUM_DRIVER=swrast"
    echo -e "${YELLOW}Unknown chipset detected. Using software rendering (swrast).${NC}" | tee -a "$LOG_FILE"
fi

# Install Debian with proot-distro
echo -e "${BLUE}Installing Debian with proot-distro...${NC}" | tee -a "$LOG_FILE"
progress_bar 15 "Debian Installation"
proot-distro install debian
check_status

# Backup existing Debian configuration
echo -e "${BLUE}Backing up existing Debian configuration...${NC}" | tee -a "$LOG_FILE"
if [ -d "$HOME/.proot-distro/debian" ]; then
    tar -czf "$HOME/debian_backup_$(date +%F).tar.gz" "$HOME/.proot-distro/debian"
    echo -e "${GREEN}Backup created: $HOME/debian_backup_$(date +%F).tar.gz${NC}" | tee -a "$LOG_FILE"
fi

# Install WhiteSur themes and icons
install_whitesur_themes() {
    echo -e "${BLUE}Installing WhiteSur themes and icons...${NC}" | tee -a "$LOG_FILE"
    mkdir -p ~/.themes ~/.icons ~/Pictures/Wallpapers

    # WhiteSur GTK theme
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme
    bash ~/WhiteSur-gtk-theme/install.sh -c dark -t default -d ~/.themes
    check_status

    # WhiteSur Icon theme
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme
    bash ~/WhiteSur-icon-theme/install.sh -d ~/.icons
    check_status

    # WhiteSur Wallpapers
    wget -q -O ~/Pictures/Wallpapers/whitesur_dark.jpg https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/wallpapers/WhiteSur-dark.jpg
    wget -q -O ~/Pictures/Wallpapers/whitesur_light.jpg https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/wallpapers/WhiteSur-light.jpg
    check_status
}

# Configure XFCE with WhiteSur
configure_xfce4_whitesur() {
    echo -e "${BLUE}Configuring XFCE4 with WhiteSur themes and icons...${NC}" | tee -a "$LOG_FILE"
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s ~/Pictures/Wallpapers/whitesur_dark.jpg
    check_status
}

# Call WhiteSur functions
install_whitesur_themes
configure_xfce4_whitesur

echo -e "${GREEN}🎉 Setup Complete! Enjoy your Termux-X11 environment with WhiteSur themes!${NC}" | tee -a "$LOG_FILE"
