#!/data/data/com.termux/files/usr/bin/bash

# Script to automate Alpine Linux + XFCE4 + Chromium setup with Termux:X11 and hardware acceleration on Realme Pad Mini
# Includes sudo, nano, dbus-x11, user setup, startxfce4_alpine.sh, and fixes previous issues
# Run in Termux: chmod +x setup-alpine-xfce4-x11-realme.sh && ./setup-alpine-xfce4-x11-realme.sh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Alpine Linux + XFCE4 + Chromium setup for Realme Pad Mini...${NC}"

# Step 1: Setup storage permissions
echo -e "${YELLOW}Setting up storage permissions...${NC}"
termux-setup-storage
sleep 2  # Wait for permissions to be applied

# Step 2: Configure mirrors and enable x11-repo
echo -e "${YELLOW}Configuring mirrors and enabling x11-repo...${NC}"
pkg install -y termux-tools
termux-change-repo
# Create sources.list.d directory if it doesn't exist
mkdir -p $PREFIX/etc/apt/sources.list.d
echo "deb https://packages.termux.dev/apt/termux-x11/ x11 main" > $PREFIX/etc/apt/sources.list.d/x11.list
apt update -y

# Step 3: Clean up conflicting packages and update Termux
echo -e "${YELLOW}Cleaning up conflicting packages and updating Termux...${NC}"
apt autoclean
apt autoremove -y
pkg update -y && pkg upgrade -y
pkg install -y x11-repo termux-x11-nightly pulseaudio proot-distro wget

# Step 4: Install hardware acceleration packages
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

# Step 5: Install Alpine Linux
echo -e "${YELLOW}Installing Alpine Linux...${NC}"
proot-distro install alpine

# Step 6: Configure Alpine Linux
echo -e "${YELLOW}Configuring Alpine Linux with XFCE4, Chromium, and user setup...${NC}"
proot-distro login alpine --shared-tmp << 'EOF'
  # Update Alpine repositories and enable community repo
  apk update
  apk upgrade
  sed -i 's/#http/http/' /etc/apk/repositories
  apk update

  # Install XFCE4, Xorg, Chromium, and dependencies
  apk add sudo nano dbus-x11 xfce4 xorg-server xf86-video-fbdev mesa-demos chromium

  # Create user 'enayat' with a default password (change later for security)
  adduser -h /home/enayat -s /bin/sh enayat
  echo "enayat:nahi@123" | chpasswd

  # Configure sudoers for 'enayat'
  echo "enayat ALL=(ALL:ALL) ALL" >> /etc/sudoers

  # Create a startup script for XFCE4 with hardware acceleration
  cat > /root/start-xfce4.sh << 'START_XFCE4'
#!/bin/sh
export DISPLAY=:0
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=3.3
startxfce4
START_XFCE4
  chmod +x /root/start-xfce4.sh
EOF

# Step 7: Download and configure startxfce4_alpine.sh
echo -e "${YELLOW}Downloading and configuring startxfce4_alpine.sh...${NC}"
wget -O $HOME/startxfce4_alpine.sh https://raw.githubusercontent.com/LinuxDroidMaster/Termux-Desktops/main/scripts/proot_alpine/startxfce4_alpine.sh
chmod +x $HOME/startxfce4_alpine.sh

# Step 8: Create Termux startup script
echo -e "${YELLOW}Creating Termux startup script for Termux:X11 and XFCE4...${NC}"
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

# Run startxfce4_alpine.sh as user 'enayat'
proot-distro login alpine --shared-tmp --user enayat -- /home/enayat/startxfce4_alpine.sh
START_X11
chmod +x $HOME/start-alpine-x11.sh

# Step 9: Copy startxfce4_alpine.sh to user 'enayat' home directory
echo -e "${YELLOW}Copying startxfce4_alpine.sh to user 'enayat' home directory...${NC}"
proot-distro login alpine --shared-tmp << 'EOF'
  cp /root/startxfce4_alpine.sh /home/enayat/startxfce4_alpine.sh
  chown enayat:enayat /home/enayat/startxfce4_alpine.sh
  chmod +x /home/enayat/startxfce4_alpine.sh
EOF

# Step 10: Instructions for user
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To start the Alpine XFCE4 GUI with hardware acceleration:${NC}"
echo -e "1. Install and open the Termux:X11 app from F-Droid."
echo -e "2. Run the following command in Termux:"
echo -e "   ${GREEN}./start-alpine-x11.sh${NC}"
echo -e "3. The XFCE4 desktop should appear in Termux:X11 as user 'enayat' with Chromium installed."
echo -e "${YELLOW}To test hardware acceleration:${NC}"
echo -e "   In Alpine, run 'glxge personally as user 'enayat':"
echo -e "   ${GREEN}proot-distro login alpine --user enayat${NC}"
echo -e "   Then run 'glxgears' (expect 40-60 FPS with Mali-G52)."
echo -e "${YELLOW}To use Chromium:${NC}"
echo -e "   In XFCE4, open the menu and launch Chromium. Limit open tabs to 1-2 for best performance."
echo -e "${YELLOW}User credentials:${NC}"
echo -e "   Username: enayat"
echo -e "   Password: password123 (change it with 'passwd' after logging in)"
echo -e "${RED}Note:${NC} Realme Pad Mini's 3-4 GB RAM may slow down with multiple Chromium tabs or XFCE4. Close background apps. Ensure ~1.5-2 GB free storage (check with 'df -h'). If issues occur, check logs or try MESA_GL_VERSION_OVERRIDE=3.2 in /root/start-xfce4.sh."

# Step 11: Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
apt clean
