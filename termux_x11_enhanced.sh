#!/data/data/com.termux/files/usr/bin/bash

# Script to set up LXDE on Debian proot-distro with X11, GPU acceleration, Zsh, and a theme.

# Constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
USERNAME="lxdeuser"

# Exit on error
set -e

# Log messages with timestamps
log() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Error handler
error_exit() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Check and install Termux prerequisites
install_prerequisites() {
    log "Checking and installing prerequisites..."
    pkg update -y && pkg upgrade -y
    for pkg in x11-repo termux-x11-nightly pulseaudio proot-distro wget git tur-repo \
                mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            log "Installing $pkg..."
            pkg install -y "$pkg" || error_exit "Failed to install $pkg"
        fi
    done
}

# Detect chipset for GPU optimization
detect_chipset() {
    log "Detecting chipset..."
    CHIPSET=$(getprop ro.hardware)
    GPU=$(getprop ro.hardware.gpu)

    if [[ "$CHIPSET" == *"qcom"* || "$GPU" == *"adreno"* ]]; then
        DRIVER="zink"
        log "Qualcomm Adreno GPU detected. Using Zink (Vulkan) for acceleration."
        if [[ "$GPU" == *"adreno"* ]]; then
            install_turnip_driver
        fi
    else
        DRIVER="virpipe"
        log "Non-Qualcomm chipset detected. Falling back to VirGL for acceleration."
    fi
}

# Install Turnip driver for Adreno GPUs
install_turnip_driver() {
    log "Installing Turnip driver for Adreno GPU..."
    wget -q https://github.com/MatrixhKa/mesa-turnip/releases/download/24.1.0/mesa-turnip-kgsl-24.1.0-devel.zip -O turnip.zip
    unzip -q turnip.zip -d turnip
    sudo mv turnip/libvulkan_freedreno.so /usr/lib/
    sudo mv turnip/freedreno_icd.aarch64.json /usr/share/vulkan/icd.d/
    rm -rf turnip turnip.zip
    log "Turnip driver installed successfully."
}

# Install Debian proot-distro
install_debian_proot() {
    log "Installing Debian proot-distro..."
    if ! proot-distro list | grep -q "debian"; then
        proot-distro install debian || error_exit "Failed to install Debian."
    else
        log "Debian is already installed."
    fi
}

# Set up Debian user and install LXDE
setup_debian() {
    log "Creating user $USERNAME in Debian and installing LXDE..."
    proot-distro login debian --user root -- bash -c "
        useradd -m -s /bin/bash $USERNAME && echo '$USERNAME:password' | chpasswd;
        apt update && apt upgrade -y;
        apt install -y lxde dbus-x11 x11-xserver-utils mesa-utils;
    " || error_exit "Failed to set up Debian."
}

# Create LXDE start script
create_start_script() {
    log "Creating LXDE start script..."
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
    chmod +x startlxde_debian.sh
}

# Install Zsh and configure theme
install_zsh_with_theme() {
    log "Installing Zsh and configuring Oh-My-Zsh with a theme..."

    # Install Zsh
    pkg install -y zsh || error_exit "Failed to install Zsh."

    # Install Oh-My-Zsh
    log "Installing Oh-My-Zsh..."
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || error_exit "Failed to install Oh-My-Zsh."

    # Set Zsh as the default shell for the Termux user
    chsh -s zsh

    # Install a theme (e.g., 'agnoster' or 'powerlevel10k')
    log "Setting up Zsh theme..."
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc || error_exit "Failed to configure Zsh theme."

    # Optionally, install Powerlevel10k for advanced configuration
    log "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    sed -i 's/ZSH_THEME="agnoster"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc || error_exit "Failed to configure Powerlevel10k theme."

    log "${GREEN}Zsh and theme setup complete! Restart the terminal to apply changes.${NC}"
}

# Clean up
cleanup() {
    log "Cleaning up temporary files..."
    apt clean
    proot-distro login debian --user root -- bash -c "apt clean"
}

# Main execution
main() {
    install_prerequisites
    detect_chipset
    install_debian_proot
    setup_debian
    create_start_script
    install_zsh_with_theme
    cleanup
    log "${GREEN}Setup complete! Run ./startlxde_debian.sh to start LXDE.${NC}"
}

main
