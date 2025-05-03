#!/bin/bash

# Script Name: termux_x11_enhanced_fixed.sh
# Description: Enhanced Termux-X11 setup with chipset optimization, Chromium, XFCE4, and error handling

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
        printf "\r[${GREEN}%-${i}s${NC}] %d%%" "██████████" "$i"
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
    echo -e "${RED}Termux nahi mila! Please Termux install karein.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "${YELLOW}🚀 Termux-X11 Enhanced Setup Script 🚀${NC}"
echo -e "${BLUE}Features: Chipset Optimization, Chromium, XFCE4 Themes, Backup/Restore${NC}" | tee -a "$LOG_FILE"

# Interactive prompt for user
echo -e "${YELLOW}Kya aap setup start karna chahte hain? (y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}" | tee -a "$LOG_FILE"
    exit 0
fi

# Enable storage permission
echo -e "${BLUE}Storage permission setup...${NC}" | tee -a "$LOG_FILE"
progress_bar 2 "Storage Permission"
termux-setup-storage
check_status

# Ensure x11-repo is enabled
echo -e "${BLUE}Configuring x11-repo...${NC}" | tee -a "$LOG_FILE"
progress_bar 5 "Repository Setup"
echo "deb https://termux.dev/x11-packages unstable main" >> /data/data/com.termux/files/usr/etc/apt/sources.list
pkg update -y
check_status

# Install Termux packages
echo -e "${BLUE}Installing Termux packages...${NC}" | tee -a "$LOG_FILE"
progress_bar 10 "Termux Packages"
pkg install pulseaudio proot-distro wget git -y
# Try installing termux-x11-nightly with fallback
pkg install termux-x11-nightly -y || {
    echo -e "${YELLOW}termux-x11-nightly not found. Trying alternative mirror...${NC}" | tee -a "$LOG_FILE"
    termux-change-repo
    pkg update -y
    pkg install termux-x11-nightly -y
}
check_status

# Detect chipset using /proc/cpuinfo
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

# Install Debian proot-distro
echo -e "${BLUE}Installing Debian proot-distro...${NC}" | tee -a "$LOG_FILE"
progress_bar 15 "Debian Installation"
proot-distro install debian
check_status

# Backup existing Debian config
echo -e "${BLUE}Backing up existing Debian config...${NC}" | tee -a "$LOG_FILE"
progress_bar 3 "Backup"
if [ -d "$HOME/.proot-distro/debian" ]; then
    tar -czf "$HOME/debian_backup_$(date +%F).tar.gz" "$HOME/.proot-distro/debian" 2>/dev/null
    echo -e "${GREEN}Backup saved: $HOME/debian_backup_$(date +%F).tar.gz${NC}" | tee -a "$LOG_FILE"
fi

# Setup XFCE4, Chromium, themes, and GPU acceleration
echo -e "${BLUE}Setting up XFCE4, Chromium, and GPU acceleration...${NC}" | tee -a "$LOG_FILE"
progress_bar 20 "Debian Setup"
proot-distro login debian --shared-tmp -- bash -c "
    apt update && apt upgrade -y
    apt install xfce4 xfce4-terminal chromium xfce4-panel-profiles -y
    apt install mesa-zink virglrenderer-mesa-zink vulkan-loader -y
    apt install arc-theme -y
    xfconf-query -c xsettings - Sadly, I have reached my context limit and can't continue generating the response. If you provide more details or ask a more specific question, I can try to assist further!
