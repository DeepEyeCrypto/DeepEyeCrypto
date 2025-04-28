#!/data/data/com.termux/files/usr/bin/bash

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to automate Kali NetHunter installation on Termux with colors

# Step 1: Banner and prerequisites check
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}Kali Linux Full Installer for Termux${NC}"
echo -e "${CYAN}=====================================${NC}"
echo -e "${YELLOW}Ensure 4GB+ free storage and stable internet.${NC}"
echo -e "${YELLOW}This script installs Kali NetHunter Full with VNC.${NC}"
echo -e "${CYAN}=====================================${NC}"

# Check internet connectivity
echo -e "${BLUE}Checking internet connection...${NC}"
ping -c 1 google.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: No internet connection. Please connect and retry.${NC}"
    exit 1
fi
echo -e "${GREEN}Internet connection verified.${NC}"

# Step 2: Update and upgrade Termux packages
echo -e "${BLUE}Updating Termux packages...${NC}"
pkg update -y && pkg upgrade -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to update Termux. Check internet or package manager.${NC}"
    exit 1
fi
echo -e "${GREEN}Termux packages updated.${NC}"

# Step 3: Grant storage permission
echo -e "${BLUE}Granting storage permission...${NC}"
termux-setup-storage
sleep 2
echo -e "${GREEN}Storage permission granted.${NC}"

# Step 4: Install wget and curl
echo -e "${BLUE}Installing wget and curl...${NC}"
pkg install wget curl -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to install wget or curl. Exiting.${NC}"
    exit 1
fi
echo -e "${GREEN}wget and curl installed.${NC}"

# Step 5: Download NetHunter installer script (using updated URL)
echo -e "${BLUE}Downloading Kali NetHunter installer...${NC}"
wget -O install-nethunter-termux https://offs.ec/2MceZWr || {
    echo -e "${YELLOW}Warning: Failed to download from primary URL. Trying alternative...${NC}"
    curl -fsSLO https://raw.githubusercontent.com/jorexdeveloper/termux-nethunter/main/install-nethunter.sh
    mv install-nethunter.sh install-nethunter-termux
}
if [ ! -f install-nethunter-termux ]; then
    echo -e "${RED}Error: Failed to download installer. Check internet or manually download from https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project.${NC}"
    exit 1
fi
echo -e "${GREEN}Installer downloaded successfully.${NC}"

# Step 6: Make the script executable
echo -e "${BLUE}Making installer executable...${NC}"
chmod +x install-nethunter-termux
echo -e "${GREEN}Installer is now executable.${NC}"

# Step 7: Run the installer with full version selection
echo -e "${BLUE}Installing Kali NetHunter Full (this may take a while)...${NC}"
echo "1" | ./install-nethunter-termux
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Installation failed. Check storage, internet, or URL. Try manual download of kalifs-arm64-full.tar.xz from https://images.kali.org/nethunter/.${NC}"
    exit 1
fi
echo -e "${GREEN}Kali NetHunter Full installed successfully.${NC}"

# Step 8: Update Kali Linux
echo -e "${BLUE}Updating Kali Linux packages...${NC}"
nethunter -c "sudo apt update && sudo apt full-upgrade -y"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Failed to update Kali. Run 'sudo apt update' manually later.${NC}"
    echo -e "${YELLOW}If you see 'Temporary failure resolving http.kali.org', edit /etc/apt/sources.list to use 'deb https://http.kali.org/kali kali-rolling main non-free contrib'.${NC}"
fi
echo -e "${GREEN}Kali packages updated (or will be updated manually).${NC}"

# Step 9: Prompt for VNC password
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}Setting up VNC for Kali GUI...${NC}"
echo -e "${BLUE}Enter a VNC password (up to 8 characters):${NC}"
read -s vnc_password
if [ ${#vnc_password} -gt 8 ]; then
    echo -e "${RED}Error: VNC password must be 8 characters or less.${NC}"
    exit 1
fi
echo -e "${GREEN}VNC password accepted.${NC}"

# Step 10: Configure VNC password
echo -e "${BLUE}Configuring VNC password...${NC}"
nethunter kex passwd <<EOF
$vnc_password
$vnc_password
EOF
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to set VNC password. Run 'nethunter kex passwd' manually.${NC}"
    exit 1
fi
echo -e "${GREEN}VNC password configured.${NC}"

# Step 11: Start VNC server
echo -e "${BLUE}Starting VNC server...${NC}"
nethunter kex &
sleep 2
echo -e "${GREEN}VNC server started.${NC}"

# Step 12: Final instructions
echo -e "${CYAN}=====================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${CYAN}=====================================${NC}"
echo -e "${YELLOW}To access Kali CLI:${NC} Run 'nethunter' or 'nh'."
echo -e "${YELLOW}To access Kali GUI:${NC}"
echo -e "${YELLOW}1. Open NetHunter KeX app (from store.nethunter.com).${NC}"
echo -e "${YELLOW}2. Connect to 127.0.0.1:5901 with your VNC password.${NC}"
echo -e "${YELLOW}To stop VNC:${NC} Run 'nethunter kex stop'."
echo -e "${YELLOW}To uninstall:${NC} Rerun './install-nethunter-termux' and select uninstall."
echo -e "${CYAN}=====================================${NC}"
echo -e "${YELLOW}Troubleshooting:${NC}"
echo -e "${YELLOW}- Signal 9 error (Android 12+): Run 'adb shell settings put global phantom_processes_limit -1' and disable Termux battery optimization.${NC}"
echo -e "${YELLOW}- 404 errors: Manually download kalifs-arm64-full.tar.xz from https://images.kali.org/nethunter/ and place it in Termux home.${NC}"
echo -e "${YELLOW}- APT update errors: See https://www.kali.org/docs/troubleshooting/apt-update-fails/.${NC}"
echo -e "${CYAN}=====================================${NC}"
