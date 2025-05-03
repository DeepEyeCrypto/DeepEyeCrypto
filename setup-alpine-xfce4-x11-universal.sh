#!/data/data/com.termux/files/usr/bin/bash

# Script to automate Alpine Linux + XFCE4 + Chromium setup with Termux:X11 and hardware acceleration for all Android devices
# Auto-detects chipset, configures GPU acceleration, includes sudo, nano, dbus-x11, user setup
# Removes startxfce4_alpine.sh dependency, integrates XFCE4 startup, fixes previous issues
# Run in Termux: chmod +x setup-alpine-xfce4-x11-universal.sh && ./setup-alpine-xfce4-x11-universal.sh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file (use $HOME to avoid /sdcard permission issues)
LOG_FILE="$HOME/termux_setup.log"
echo "Setup started: $(date)" > $LOG_FILE

echo -e "${GREEN}Starting Alpine Linux + XFCE4 + Chromium setup for your device...${NC}"

# Step 1: Setup storage permissions
echo -e "${YELLOW}Setting up storage permissions...${NC}" | tee -a $LOG_FILE
termux-setup-storage
sleep 5  # Extended wait for permissions to be applied
# Verify storage access
if ! touch /sdcard/termux_test.txt 2>/dev/null; then
    echo -e "${YELLOW}Warning: Cannot write to /sdcard. Logs will be saved to $LOG_FILE instead.${NC}" | tee -a $LOG_FILE
else
    rm /sdcard/termux_test.txt
fi

# Step 2: Check RAM and storage
echo -e "${YELLOW}Checking RAM and storage...${NC}" | tee -a $LOG_FILE
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
FREE_STORAGE=$(df -h /data | awk 'NR==2 {print $4}' | grep -o '[0-9.]*')
if [ $TOTAL_RAM -lt 2000 ]; then
    echo -e "${RED}Warning: Low RAM ($TOTAL_RAM MB). Close background apps for best performance.${NC}" | tee -a $LOG_FILE
fi
if (( $(echo "$FREE_STORAGE < 1.5" | bc -l) )); then
    echo -e "${RED}Error: Insufficient storage ($FREE_STORAGE GB). Need ~1.5-2 GB. Free up space or use microSD.${NC}" | tee -a $LOG_FILE
    exit 1
fi

# Step 3: Auto-detect chipset and GPU
echo -e "${YELLOW}Detecting chipset and GPU...${NC}" | tee -a $LOG_FILE
CHIPSET=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
if [ -z "$CHIPSET" ]; then
    CHIPSET=$(cat /proc/cpuinfo | grep "Hardware" | awk -F: '{print $2}' | xargs)
fi
# Use dmesg to detect GPU (fallback to Unknown if not found)
GPU_INFO=$(dmesg | grep -iE 'mali|adreno|powervr' | head -n 1 | awk '{print $NF}' | xargs || echo "Unknown")
if [ "$GPU_INFO" = "Unknown" ]; then
    GPU_INFO=$(cat /proc/cpuinfo | grep -iE 'mali|adreno|powervr' | head -n 1 | awk '{print $NF}' | xargs || echo "Unknown")
fi
echo -e "${GREEN}Detected Chipset: $CHIPSET${NC}" | tee -a $LOG_FILE
echo -e "${GREEN}Detected GPU: $GPU_INFO${NC}" | tee -a $LOG_FILE

# Set OpenGL version based on GPU
if echo "$GPU_INFO" | grep -qi "Adreno"; then
    GL_VERSION="4.0"
    GALLIUM_DRIVER="zink"
elif echo "$GPU_INFO" | grep -qi "Mali"; then
    GL_VERSION="3.3"
    GALLIUM_DRIVER="zink"
elif echo "$GPU_INFO" | grep -qi "PowerVR"; then
    GL_VERSION="3.2"
    GALLIUM_DRIVER="virpipe"
else
    GL_VERSION="3.2"
    GALLIUM_DRIVER="virpipe"
    echo -e "${YELLOW}Unknown GPU, using conservative settings (OpenGL ES fallback).${NC}" | tee -a $LOG_FILE
fi
echo -e "${GREEN}Selected OpenGL version: $GL_VERSION, Gallium Driver: $GALLIUM_DRIVER${NC}" | tee -a $LOG_FILE

# Step 4: Configure mirrors and enable x11-repo
echo -e "${YELLOW}Configuring mirrors and enabling x11-repo...${NC}" | tee -a $LOG_FILE
pkg install -y termux-tools
termux-change-repo
mkdir -p $PREFIX/etc/apt/sources.list.d
echo "deb https://packages.termux.dev/apt/termux-x11/ x11 main" > $PREFIX/etc/apt/sources.list.d/x11.list
apt update -y

# Step 5: Clean up conflicting packages and update Termux
echo -e "${YELLOW}Cleaning up conflicting packages and updating Termux...${NC}" | tee -a $LOG_FILE
apt autoclean
apt autoremove -y
pkg update -y && pkg upgrade -y
pkg install -y x11-repo termux-x11-nightly pulseaudio proot-distro

# Step 6: Install hardware acceleration packages
echo -e "${YELLOW}Installing VirGL and Zink for GPU acceleration...${NC}" | tee -a $LOG_FILE
if dpkg -l | grep -q vulkan-loader-generic; then
    pkg uninstall -y vulkan-loader-generic
fi
if ! pkg install -y mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android; then
    echo -e "${RED}Failed to install mesa-zink or virglrenderer-mesa-zink. Falling back to virglrenderer-android...${NC}" | tee -a $LOG_FILE
    pkg install -y vulkan-loader-android virglrenderer-android
fi

# Step 7: Install Alpine Linux
echo -e "${YELLOW}Installing Alpine Linux...${NC}" | tee -a $LOG_FILE
proot-distro install alpine

# Step 8: Configure Alpine Linux
echo -e "${YELLOW}Configuring Alpine Linux with XFCE4, Chromium, and user setup...${NC}" | tee -a $LOG_FILE
proot-distro login alpine --shared-tmp --no-sysvipc << EOF
  # Update Alpine repositories and enable community repo
  apk update
  apk upgrade
  sed -i 's/#http/http/' /etc/apk/repositories
  apk update

  # Install XFCE4, Xorg, Chromium, and dependencies
  apk add sudo nano dbus-x11 xfce4 xorg-server xf86-video-fbdev mesa-demos chromium

  # Create user 'enayat' with a default password (change later for security)
  adduser -h /home/enayat -s /bin/sh enayat
  echo "enayat:password123" | chpasswd

  # Configure sudoers for 'enayat'
  echo "enayat ALL=(ALL:ALL) ALL" >> /etc/sudoers

  # Create a startup script for XFCE4 with hardware acceleration
  cat > /home/enayat/start-xfce4.sh << START_XFCE4
#!/bin/sh
export DISPLAY=:0
export GALLIUM_DRIVER=$GALLIUM_DRIVER
export MESA_GL_VERSION_OVERRIDE=$GL_VERSION
export XDG_RUNTIME_DIR=/home/enayat/.xdg
mkdir -p \$XDG_RUNTIME_DIR
startxfce4
START_XFCE4
  chown enayat:enayat /home/enayat/start-xfce4.sh
  chmod +x /home/enayat/start-xfce4.sh
EOF

# Step 9: Create Termux startup script
echo -e "${YELLOW}Creating Termux startup script for Termux:X11 and XFCE4...${NC}" | tee -a $LOG_FILE
cat > $HOME/start-alpine-x11.sh << START_X11
#!/data/data/com.termux/files/usr/bin/bash

# Start PulseAudio for sound
pulseaudio --start

# Start VirGL server with Zink
MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=$GL_VERSION MESA_GLES_VERSION_OVERRIDE=3.2 \\
GALLIUM_DRIVER=$GALLIUM_DRIVER ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &

# Start Termux:X11
termux-x11 :0 &

# Wait for Termux:X11 to initialize
sleep 2

# Run XFCE4 as user 'enayat'
proot-distro login alpine --shared-tmp --no-sysvipc --user enayat -- /home/enayat/start-xfce4.sh
START_X11
chmod +x $HOME/start-alpine-x11.sh

# Step 10: Verify XFCE4 installation
echo -e "${YELLOW}Verifying XFCE4 installation...${NC}" | tee -a $LOG_FILE
proot-distro login alpine --shared-tmp --no-sysvipc << EOF
  if ! command -v startxfce4 >/dev/null; then
      echo "Error: XFCE4 not installed properly." >> $LOG_FILE
      exit 1
  fi
  if ! id enayat >/dev/null 2>&1; then
      echo "Error: User 'enayat' not created properly." >> $LOG_FILE
      exit 1
  fi
  if [ ! -f /home/enayat/start-xfce4.sh ]; then
      echo "Error: /home/enayat/start-xfce4.sh not created." >> $LOG_FILE
      exit 1
  fi
EOF

# Step 11: Instructions for user
echo -e "${GREEN}Setup complete!${NC}" | tee -a $LOG_FILE
echo -e "${YELLOW}To start the Alpine XFCE4 GUI with hardware acceleration:${NC}"
echo -e "1. Install and open the Termux:X11 app from F-Droid."
echo -e "2. Run the following command in Termux:"
echo -e "   ${GREEN}./start-alpine-x11.sh${NC}"
echo -e "3. The XFCE4 desktop should appear in Termux:X11 as user 'enayat' with Chromium installed."
echo -e "${YELLOW}To test hardware acceleration:${NC}"
echo -e "   Log in as 'enayat':"
echo -e "   ${GREEN}proot-distro login alpine --user enayat${NC}"
echo -e "   Then run 'glxgears' (expect 40-60 FPS with detected GPU)."
echo -e "${YELLOW}To use Chromium:${NC}"
echo -e "   In XFCE4, open the menu and launch Chromium. Limit open tabs to 1-2."
echo -e "${YELLOW}User credentials:${NC}"
echo -e "   Username: enayat"
echo -e "   Password: password123 (change with 'passwd' after login)"
echo -e "${RED}Note:${NC} Your device's $TOTAL_RAM MB RAM may slow down with multiple tabs or XFCE4. Close background apps. Ensure ~1.5-2 GB free storage (check with 'df -h'). Logs saved to $LOG_FILE. If issues occur, try MESA_GL_VERSION_OVERRIDE=3.2 in /home/enayat/start-xfce4.sh."

# Step 12: Clean up
echo -e "${YELLOW}Cleaning up...${NC}" | tee -a $LOG_FILE
apt clean
