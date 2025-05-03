#!/data/data/com.termux/files/usr/bin/bash

# Script to set up LXDE on Debian proot-distro with X11 and hardware acceleration
# Optimized for chipset detection and GPU acceleration (VirGL/Zink/Turnip)

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Termux is installed correctly
if ! command -v pkg &> /dev/null; then
    echo -e "${RED}Termux package manager not found. Please install Termux correctly.${NC}"
    exit 1
fi

# Update Termux and install prerequisites
echo -e "${YELLOW}Updating Termux and installing prerequisites...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y x11-repo termux-x11-nightly pulseaudio proot-distro wget git tur-repo

# Install hardware acceleration packages
echo -e "${YELLOW}Installing hardware acceleration packages...${NC}"
pkg install -y mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android

# Detect chipset for GPU optimization
echo -e "${YELLOW}Detecting chipset...${NC}"
CHIPSET=$(getprop ro.hardware)
GPU=$(getprop ro.hardware.gpu)

if [[ "$CHIPSET" == *"qcom"* || "$GPU" == *"adreno"* ]]; then
    DRIVER="zink"
    echo -e "${GREEN}Qualcomm Adreno GPU detected. Using Zink (Vulkan) for acceleration.${NC}"
    # Check for Turnip compatibility (Adreno 610+)
    if [[ "$GPU" == *"adreno"* ]]; then
        echo -e "${YELLOW}Checking for Turnip driver compatibility...${NC}"
        wget -q https://github.com/MatrixhKa/mesa-turnip/releases/download/24.1.0/mesa-turnip-kgsl-24.1.0-devel.zip -O turnip.zip
        unzip -q turnip.zip -d turnip
        cd turnip
        sudo mkdir -p /usr/share/vulkan/icd.d/
        sudo mv libvulkan_freedreno.so /usr/lib/
        sudo mv freedreno_icd.aarch64.json /usr/share/vulkan/icd.d/
        cd .. && rm -rf turnip turnip.zip
        echo -e "${GREEN}Turnip driver installed for Adreno GPU.${NC}"
    fi
else
    DRIVER="virpipe"
    echo -e "${YELLOW}Non-Qualcomm chipset detected. Falling back to VirGL for acceleration.${NC}"
fi

# Install Debian proot-distro
echo -e "${YELLOW}Installing Debian proot-distro...${NC}"
if ! proot-distro list | grep -q "debian"; then
    proot-distro install debian
else
    echo -e "${GREEN}Debian already installed.${NC}"
fi

# Create a user in Debian proot-distro
USERNAME="lxdeuser"
echo -e "${YELLOW}Creating user $USERNAME in Debian...${NC}"
proot-distro login debian --user root -- bash -c "
    useradd -m -s /bin/bash $USERNAME
    echo '$USERNAME:password' | chpasswd
"

# Install LXDE and dependencies in Debian
echo -e "${YELLOW}Installing LXDE and dependencies in Debian...${NC}"
proot-distro login debian --user root -- bash -c "
    apt update && apt upgrade -y
    apt install -y lxde dbus-x11 x11-xserver-utils mesa-utils
"

# Create start script for LXDE with hardware acceleration
echo -e "${YELLOW}Creating start script for LXDE...${NC}"
cat > startlxde_debian.sh << EOL
#!/data/data/com.termux/files/usr/bin/bash

# Start pulseaudio for sound
pulseaudio --start

# Start Termux X11
termux-x11 :0 &

# Wait for X11 to start
sleep 2

# Start virgl_test_server for hardware acceleration
if [ "$DRIVER" = "zink" ]; then
    MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 \
    GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &
else
    GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 virgl_test_server --use-egl-surfaceless &
fi

# Login to Debian proot-distro and start LXDE
proot-distro login debian --user $USERNAME --shared-tmp -- bash -c "
    export DISPLAY=:0
    export PULSE_SERVER=tcp:127.0.0.1:4713
    GALLIUM_DRIVER=$DRIVER MESA_GL_VERSION_OVERRIDE=4.0 dbus-launch --exit-with-session startlxde
"
EOL

# Make the script executable
chmod +x startlxde_debian.sh

# Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
apt clean
proot-distro login debian --user root -- bash -c "apt clean"

# Instructions for the user
echo -e "${GREEN}Setup complete! To start LXDE with hardware acceleration:${NC}"
echo -e "1. Ensure Termux X11 app is installed from GitHub releases."
echo -e "2. Run the following command in Termux:"
echo -e "   ${YELLOW}./startlxde_debian.sh${NC}"
echo -e "3. If you encounter issues, check logs in /tmp/ or ensure Termux X11 is not already running."
echo -e "4. To stop, press Ctrl+C in Termux and close Termux X11 app."

# Warn about potential issues
echo -e "${YELLOW}Note:${NC}"
echo -e "- For Qualcomm devices, Zink/Turnip is used for Vulkan acceleration."
echo -e "- For other chipsets, VirGL is used, which may have lower performance."
echo -e "- If XFCE4 or other desktops were previously installed, conflicts may occur."
echo -e "- Ensure your device has at least 4GB RAM for smooth performance."
echo -e "- Turnip is experimental and may break on some Adreno GPUs (e.g., 710, 642L)."

exit 0
