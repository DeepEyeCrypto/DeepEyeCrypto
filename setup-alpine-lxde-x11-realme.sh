#!/data/data/com.termux/files/usr/bin/bash

# Script to automate Alpine Linux + LXDE + Chromium setup with Termux:X11 and hardware acceleration on Realme Pad Mini
# Fixes x11-repo issues, vulkan-loader-android conflict, and adds Chromium
# Run in Termux: chmod +x setup-alpine-lxde-x11-realme.sh && ./setup-alpine-lxde-x11-realme.sh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Alpine Linux + LXDE + Chromium setup for Realme Pad Mini...${NC}"

# Step 1: Configure mirrors and enable x11-repo
echo -e "${YELLOW}Configuring mirrors and enabling x11-repo...${NC}"
pkg install -y termux-tools
termux-change-repo
echo "deb https://packages.termux.dev/apt/termux-x11/ x11 main" > $PREFIX/etc/apt/sources.list.d/x11.list
apt update -y

# Step 2: Clean up conflicting packages and update Termux
echo -e "${YELLOW}Cleaning up conflicting packages and updating Termux...${NC}"
apt autoclean
apt autoremove -y
pkg update -y && pkg upgrade -y
pkg install -y termux-x11-nightly pulseaudio proot-distro

# Step 3: Install hardware acceleration packages
echo -e "${YELLOW}Installing VirGL and Zink for Mali-G52 GPU...${NC}"
# Uninstall vulkan-loader-generic if present
if dpkg -l | grep -q vulkan-loader-generic; then
    pkg uninstall -y vulkan-loader-generic
fi
# Attempt to install mesa-zink and virglrenderer-mesa-zink, fallback to virglrenderer-android
if ! pkg install -y mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android; then
    echo -e "${RED}Failed to install mesa-zink or virglrenderer-mesa-zink. Falling back to virglrenderer-android...${NC}"
    pkg install -y vulkan-loader-android virglrenderer-android
fi

# Step 4: Install Alpine Linux
echo -e "${YELLOW}Installing Alpine Linux...${NC}"
proot-distro install alpine

# Step 5: Configure Alpine Linux
echo -e "${YELLOW}Configuring Alpine Linux with LXDE, Chromium, and Xorg...${NC}"
proot-distro login alpine --shared-tmp << 'EOF'
  # Update Alpine repositories and enable community repo
  apk update
  sed -i 's/#http/http/' /etc/apk/repositories
  apk update

  # Install LXDE, Xorg, Chromium, and dependencies (minimal for Realme Pad Mini)
  apk add lxde xorg-server xf86-video-fbdev mesa-demos chromium

  # Create a startup script for LXDE with hardware acceleration
  cat > /root/start-lxde.sh << 'START_LXDE'
#!/bin/sh
export DISPLAY=:0
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=3.3
startlxde
START_LXDE
  chmod +x /root/start-lxde.sh
EOF

# Step 6: Create Termux startup script
echo -e "${YELLOW}Creating Termux startup script for Termux:X11 and VirGL...${NC}"
cat > $HOME/start-alpine-x11.sh << 'START_X11'
#!/data/data/com.termux/files/usr/bin/bash

# Start PulseAudio for sound
pulseaudio --start

# Start VirGL server with Zink (optimized for Mali-G52)
MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=3.3 MESA_GLES_VERSION_OVERRIDE=3.2 \
GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &

# Start Termux:X11
termux-x11 :0 &

# Wait for Termux:X11 to initialize
sleep 2

# Log into Alpine and start LXDE
proot-distro login alpine --shared-tmp -- /root/start-lxde.sh
START_X11
chmod +x $HOME/start-alpine-x11.sh

# Step 7: Instructions for user
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To start the Alpine LXDE GUI with hardware acceleration:${NC}"
echo -e "1. Install and open the Termux:X11 app from F-Droid."
echo -e "2. Run the following command in Termux:"
echo -e "   ${GREEN}./start-alpine-x11.sh${NC}"
echo -e "3. The LXDE desktop should appear in Termux:X11 with Chromium installed."
echo -e "${YELLOW}To test hardware acceleration:${NC}"
echo -e "   In Alpine, run 'glxgears' to check FPS (expect 40-60 FPS with Mali-G52)."
echo -e "${YELLOW}To use Chromium:${NC}"
echo -e "   In LXDE, open the menu and launch Chromium. For best performance, limit open tabs."
echo -e "${RED}Note:${NC} Realme Pad Mini's 3-4 GB RAM may slow down with multiple Chromium tabs. Close background apps. If issues occur, check logs or try MESA_GL_VERSION_OVERRIDE=3.2 in ~/start-alpine-x11.sh."

# Step 8: Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
apt clean
