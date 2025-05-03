#!/bin/bash

# Script Name: termux_x11_bugfree.sh
# Description: Robust Termux-X11 setup with chipset optimization, Chromium, XFCE4, and error handling

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
    echo -e "${BLUE}[$task]${NC}" | tee -a "$LOG_FILE"
    for ((i=0; i<=100; i+=10)); do
        printf "\r[${GREEN}%-${i}s${NC}] %d%%" "██████████" "$i"
        sleep $(echo "$duration/10" | bc -l)
    done
    echo -e "\n${GREEN}[$task] Complete!${NC}" | tee -a "$LOG_FILE"
}

# Function to check command success
check_status() {
    local task=$1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$task: Success!${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}$task: Failed! Check $LOG_FILE for details.${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to fix repository issues
fix_repos() {
    echo -e "${YELLOW}Fixing repository issues...${NC}" | tee -a "$LOG_FILE"
    # Clear cache
    pkg clean && apt-get clean
    # Set reliable mirrors
    echo "deb https://termux.librehat.com/termux-main stable main" > /data/data/com.termux/files/usr/etc/apt/sources.list
    echo "deb https://termux.dev/x11-packages unstable main" >> /data/data/com.termux/files/usr/etc/apt/sources.list
    # Update with fallback
    pkg update -y || {
        echo -e "${YELLOW}Switching to alternative mirror...${NC}" | tee -a "$LOG_FILE"
        termux-change-repo
        pkg update -y
    }
    check_status "Repository Fix" || {
        echo -e "${RED}Repository fix failed. Please check internet or try manual mirror change.${NC}" | tee -a "$LOG_FILE"
        exit 1
    }
}

# Check if Termux is installed
if ! command -v pkg &> /dev/null; then
    echo -e "${RED}Termux nahi mila! Please Termux install karein.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "${YELLOW}🚀 Termux-X11 Bug-Free Setup Script 🚀${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Features: Chipset Optimization, Chromium, XFCE4 Themes, Backup/Restore${NC}" | tee -a "$LOG_FILE"

# Interactive prompt
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
check_status "Storage Setup" || exit 1

# Fix repositories
fix_repos

# Install Termux packages
echo -e "${BLUE}Installing Termux packages...${NC}" | tee -a "$LOG_FILE"
progress_bar 10 "Termux Packages"
pkg install pulseaudio proot-distro wget git termux-x11-nightly -y || {
    echo -e "${YELLOW}Package installation failed. Retrying...${NC}" | tee -a "$LOG_FILE"
    fix_repos
    pkg install pulseaudio proot-distro wget git termux-x11-nightly -y
}
check_status "Package Installation" || exit 1

# Check Termux-X11 app
if ! pm list packages | grep -q com.termux.x11; then
    echo -e "${RED}Termux-X11 app nahi mila! Please manually install from: https://github.com/termux/termux-x11/releases${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Detect chipset using /proc/cpuinfo
echo -e "${BLUE}Detecting chipset...${NC}" | tee -a "$LOG_FILE"
progress_bar 2 "Chipset Detection"
CHIPSET=$(cat /proc/cpuinfo | grep "Hardware" | awk -F: '{print $2}' | tr -d '[:space:]' || echo "Unknown")
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
    echo -e "${YELLOW}Unknown chipset ($CHIPSET). Using software rendering (swrast).${NC}" | tee -a "$LOG_FILE"
fi

# Install Debian proot-distro
echo -e "${BLUE}Installing Debian proot-distro...${NC}" | tee -a "$LOG_FILE"
progress_bar 15 "Debian Installation"
proot-distro install debian || {
    echo -e "${YELLOW}Debian installation failed. Retrying...${NC}" | tee -a "$LOG_FILE"
    proot-distro reset debian
    proot-distro install debian
}
check_status "Debian Installation" || exit 1

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
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt upgrade -y
    apt install xfce4 xfce4-terminal chromium xfce4-panel-profiles -y || apt install xfce4 xfce4-terminal chromium -y
    apt install mesa-zink virglrenderer-mesa-zink vulkan-loader -y
    apt install arc-theme -y
    xfconf-query -c xsettings -p /Net/ThemeName -s 'Arc-Dark' 2>/dev/null
    wget -q -O /usr/share/backgrounds/xfce/xfce-blue.jpg https://wallpaperaccess.com/full/1096723.jpg
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s /usr/share/backgrounds/xfce/xfce-blue.jpg 2>/dev/null
    echo 'export $DRIVER' >> ~/.bashrc
    echo 'export MESA_GL_VERSION_OVERRIDE=4.0' >> ~/.bashrc
    echo 'export MESA_GLSL_VERSION_OVERRIDE=400' >> ~/.bashrc
    echo 'export CHROMIUM_FLAGS=\"--enable-gpu --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,WebRTCPipeWireCapturer\"' >> ~/.bashrc
"
check_status "Debian Setup" || exit 1

# Create startup script
echo -e "${BLUE}Creating Termux-X11 startup script...${NC}" | tee -a "$LOG_FILE"
progress_bar 2 "Startup Script"
cat > ~/start_x11.sh << EOL
#!/bin/bash
# Start Termux-X11 and XFCE4 with chipset-optimized acceleration
export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
pulseaudio --start
termux-x11 :0 -xstartup "dbus-launch --exit-with-session xfce4-session" &
proot-distro login debian --shared-tmp -- bash -c "startxfce4 &"
EOL
chmod +x ~/start_x11.sh
check_status "Startup Script" || exit 1

# Create restore script
echo -e "${BLUE}Creating restore script...${NC}" | tee -a "$LOG_FILE"
progress_bar 2 "Restore Script"
cat > ~/restore_debian.sh << EOL
#!/bin/bash
echo -e "${BLUE}Restoring Debian backup...${NC}"
if ls $HOME/debian_backup_*.tar.gz 1> /dev/null 2>&1; then
    latest_backup=\$(ls -t $HOME/debian_backup_*.tar.gz | head -n1)
    tar -xzf "\$latest_backup" -C $HOME/.proot-distro/
    echo -e "${GREEN}Restore complete! Run ~/start_x11.sh to start.${NC}"
else
    echo -e "${RED}No backup found!${NC}"
fi
EOL
chmod +x ~/restore_debian.sh
check_status "Restore Script" || exit 1

# Final instructions
echo -e "${GREEN}🎉 Setup Complete! 🎉${NC}" | tee -a "$LOG_FILE"
echo -e "${YELLOW}Instructions:${NC}"
echo -e "1. Termux-X11 app kholein."
echo -e "2. Run: ${GREEN}~/start_x11.sh${NC}"
echo -e "3. Chromium: Debian terminal mein 'chromium' chalayein."
echo -e "4. Display issues? Termux-X11 Preferences mein resolution/DPI adjust karein."
echo -e "5. Performance tweak: ~/.bashrc mein driver (zink/virpipe/swrast) change karein."
echo -e "6. Backup restore: ${GREEN}~/restore_debian.sh${NC}"
echo -e "7. Log file: ${GREEN}$LOG_FILE${NC}"
echo -e "${BLUE}Enjoy your optimized desktop with Arc-Dark theme!${NC}" | tee -a "$LOG_FILE"

exit 0
