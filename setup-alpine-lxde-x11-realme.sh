#!/data/data/com.termux/files/usr/bin/bash

# Script to automate Alpine Linux + LXDE setup with Termux:X11 and hardware acceleration on Realme Pad Mini
# Run in Termux: chmod +x setup-alpine-lxde-x11-realme.sh && ./setup-alpine-lxde-x11-realme.sh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Alpine Linux + LXDE setup for Realme Pad Mini...${NC}"

# Step 1: Update Termux and install prerequisites
echo -e "${YELLOW}Updating Termux and installing prerequisites...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y x11-repo
pkg install -y termux-x11-nightly pulseaudio proot-distro

# Step 2: Install hardware acceleration packages
echo -e "${YELLOW}Installing VirGL and Zink for Mali-G52 GPU...${NC}"
pkg install -y mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android

# Step 3: Install Alpine Linux
echo -e "${YELLOW}Installing Alpine Linux...${NC}"
proot-distro install alpine

# Step 4: Configure Alpine Linux
echo -e "${YELLOW}Configuring Alpine Linux with LXDE and Xorg...${NC}"
proot-distro login alpine --shared-tmp << 'EOF'
  # Update Alpine repositories and enable community repo
  apk update
  sed -i 's/#http/http/' /etc/apk/repositories
  apk update

  # Install LXDE, Xorg, and dependencies (minimal for Realme Pad Mini)
  apk add lxde xorg-server xf86-video-fbdev mesa-demos

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

# Step 5: Create Termux startup script
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

# Step 6: Instructions for user
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To start the Alpine LXDE GUI with hardware acceleration:${NC}"
echo -e "1. Install and open the Termux:X11 app from F-Droid."
echo -e "2. Run the following command in Termux:"
echo -e "   ${GREEN}./start-alpine-x11.sh${NC}"
echo -e "3. The LXDE desktop should appear in Termux:X11."
echo -e "${YELLOW}To test hardware acceleration:${NC}"
echo -e "   In Alpine, run 'glxgears' to check FPS (expect 40-60 FPS with Mali-G52)."
echo -e "${RED}Note:${NC} Realme Pad Mini's Mali-G52 GPU supports Vulkan, but performance is limited. If issues occur, check logs or try MESA_GL_VERSION_OVERRIDE=3.2."

# Step 7: Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
apt clean
