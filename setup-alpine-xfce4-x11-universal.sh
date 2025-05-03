#!/data/data/com.termux/files/usr/bin/bash

# Script to automate Alpine Linux + XFCE4 + Chromium setup with Termux:X11 and hardware acceleration for Android devices

# Exit on error and log errors
set -e
trap 'echo -e "\n${RED}An error occurred. Check the log file for details: $LOG_FILE${NC}"' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file (use $HOME to avoid /sdcard permission issues)
LOG_FILE="$HOME/termux_setup.log"
echo "Setup started: $(date)" > $LOG_FILE

# Banner
cat << "EOF"
${GREEN}
##############################################
#   Alpine Linux + XFCE4 + Chromium Setup    #
#     With Termux:X11 and GPU Acceleration   #
##############################################
${NC}
EOF

# Step 1: Prompt user for username and password
read -p "Enter the username for the new Alpine Linux user: " ALPINE_USER
while true; do
    read -s -p "Enter a password for $ALPINE_USER: " ALPINE_PASS
    echo
    read -s -p "Confirm the password: " ALPINE_PASS_CONFIRM
    echo
    [ "$ALPINE_PASS" = "$ALPINE_PASS_CONFIRM" ] && break
    echo -e "${RED}Passwords do not match. Please try again.${NC}"
done

# Step 2: Setup storage permissions
echo -e "${YELLOW}Setting up storage permissions...${NC}" | tee -a $LOG_FILE
termux-setup-storage || { echo -e "${RED}Failed to setup storage.${NC}" | tee -a $LOG_FILE; exit 1; }
sleep 5

# Test storage access
if ! touch /sdcard/termux_test.txt 2>/dev/null; then
    echo -e "${YELLOW}Warning: Cannot write to /sdcard. Logs will be saved to $LOG_FILE.${NC}" | tee -a $LOG_FILE
else
    rm /sdcard/termux_test.txt
fi

# Step 3: Check RAM and storage
echo -e "${YELLOW}Checking RAM and storage...${NC}" | tee -a $LOG_FILE
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
FREE_STORAGE=$(df -h /data | awk 'NR==2 {print $4}' | grep -o '[0-9.]*')
if [ "$TOTAL_RAM" -lt 2000 ]; then
    echo -e "${RED}Warning: Low RAM ($TOTAL_RAM MB). Close background apps for best performance.${NC}" | tee -a $LOG_FILE
fi
if (( $(echo "$FREE_STORAGE < 1.5" | bc -l) )); then
    echo -e "${RED}Error: Insufficient storage ($FREE_STORAGE GB). Free up space.${NC}" | tee -a $LOG_FILE
    exit 1
fi

# Step 4: Detect chipset and GPU
echo -e "${YELLOW}Detecting chipset and GPU...${NC}" | tee -a $LOG_FILE
CHIPSET=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs || echo "Unknown")
GPU_INFO=$(dmesg | grep -iE 'mali|adreno|powervr' | head -n 1 | awk '{print $NF}' | xargs || echo "Unknown")
echo -e "${GREEN}Detected Chipset: $CHIPSET${NC}" | tee -a $LOG_FILE
echo -e "${GREEN}Detected GPU: $GPU_INFO${NC}" | tee -a $LOG_FILE

# GPU-specific settings
case "$GPU_INFO" in
    *Adreno*) GL_VERSION="4.0"; GALLIUM_DRIVER="zink" ;;
    *Mali*) GL_VERSION="3.3"; GALLIUM_DRIVER="zink" ;;
    *PowerVR*) GL_VERSION="3.2"; GALLIUM_DRIVER="virpipe" ;;
    *) GL_VERSION="3.2"; GALLIUM_DRIVER="virpipe" ;;
esac
echo -e "${GREEN}Selected OpenGL version: $GL_VERSION, Gallium Driver: $GALLIUM_DRIVER${NC}" | tee -a $LOG_FILE

# Step 5: Enable Termux repositories and update
echo -e "${YELLOW}Configuring Termux repositories...${NC}" | tee -a $LOG_FILE
pkg install -y termux-tools || true
termux-change-repo || true
mkdir -p "$PREFIX/etc/apt/sources.list.d"
echo "deb https://packages.termux.dev/apt/termux-x11/ x11 main" > "$PREFIX/etc/apt/sources.list.d/x11.list"
apt update -y || true

# Step 6: Clean up and update Termux packages
echo -e "${YELLOW}Cleaning up and updating Termux...${NC}" | tee -a $LOG_FILE
apt autoclean
apt autoremove -y
pkg update -y && pkg upgrade -y
pkg install -y x11-repo termux-x11-nightly pulseaudio proot-distro

# Step 7: Install GPU acceleration tools
echo -e "${YELLOW}Installing GPU acceleration tools...${NC}" | tee -a $LOG_FILE
pkg install -y mesa-zink virglrenderer-mesa-zink vulkan-loader-android || {
    echo -e "${RED}Failed to install GPU acceleration tools. Falling back...${NC}" | tee -a $LOG_FILE
    pkg install -y vulkan-loader-android virglrenderer-android
}

# Step 8: Install and configure Alpine Linux
echo -e "${YELLOW}Installing and configuring Alpine Linux...${NC}" | tee -a $LOG_FILE
proot-distro install alpine
proot-distro login alpine << EOF
apk update && apk upgrade
sed -i 's/#http/http/' /etc/apk/repositories
apk update
apk add sudo nano dbus-x11 xfce4 xorg-server xf86-video-fbdev mesa-demos chromium
adduser -h /home/$ALPINE_USER -s /bin/sh $ALPINE_USER
echo "$ALPINE_USER:$ALPINE_PASS" | chpasswd
echo "$ALPINE_USER ALL=(ALL:ALL) ALL" >> /etc/sudoers
EOF

# Step 9: Create Termux startup script
echo -e "${YELLOW}Creating Termux startup script...${NC}" | tee -a $LOG_FILE
cat > "$HOME/start-alpine-x11.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
pulseaudio --start
MESA_GL_VERSION_OVERRIDE=$GL_VERSION GALLIUM_DRIVER=$GALLIUM_DRIVER virgl_test_server --use-egl-surfaceless --use-gles &
termux-x11 :0 &
sleep 2
proot-distro login alpine --shared-tmp --no-sysvipc --user $ALPINE_USER -- /home/$ALPINE_USER/start-xfce4.sh
EOF
chmod +x "$HOME/start-alpine-x11.sh"

# Final instructions
echo -e "${GREEN}Setup complete! Run './start-alpine-x11.sh' to launch the XFCE4 desktop.${NC}" | tee -a $LOG_FILE
