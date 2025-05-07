#!/bin/bash

#------------------------------------------------------------------------------
# CONFIGURATION (Adjust these for your needs)
#------------------------------------------------------------------------------
DEFAULT_USER="termuxuser"
DEFAULT_PASS="SecurePass123!"
ENABLE_GUI=true
THEME_NAME="WhiteSur"
ICON_THEME="WhiteSur-dark"
WALLPAPER_NAME="whitesur"
MESA_VERSION="24.1.0-devel-20240120"

#------------------------------------------------------------------------------
# GLOBAL VARIABLES
#------------------------------------------------------------------------------
LOG_FILE="$HOME/.config/OhMyTermux/install.log"
PKG_CACHE="$HOME/.cache/termux-packages"
DEBIAN_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/debian"

#------------------------------------------------------------------------------
# INITIALIZATION
#------------------------------------------------------------------------------
set -euo pipefail
trap 'echo -e "\n\033[38;5;196mInstallation interrupted!\033[0m"; exit 130' SIGINT

mkdir -p "$(dirname "$LOG_FILE")" "$PKG_CACHE"
exec > >(tee -a "$LOG_FILE") 2>&1

#------------------------------------------------------------------------------
# TERMUX PREPARATION
#------------------------------------------------------------------------------
prepare_termux() {
    echo -e "\n\033[38;5;33m[1/6] Preparing Termux Environment\033[0m"
    
    # Update and upgrade base system
    pkg update -y
    pkg upgrade -y
    
    # Install essential dependencies
    pkg install -y proot-distro wget gum ncurses-utils \
        x11-repo tur-repo
    
    # Setup storage access
    termux-setup-storage
}

#------------------------------------------------------------------------------
# PROOT ENVIRONMENT SETUP
#------------------------------------------------------------------------------
setup_proot() {
    echo -e "\n\033[38;5;33m[2/6] Configuring PROOT Environment\033[0m"
    
    # Install Debian if not exists
    if [ ! -d "$DEBIAN_ROOT" ]; then
        proot-distro install debian
    fi
    
    # Basic Debian configuration
    proot-distro login debian -- /bin/bash -c \
        "apt update && apt upgrade -y && apt install -y sudo neofetch"
}

#------------------------------------------------------------------------------
# CORE PACKAGE INSTALLATION
#------------------------------------------------------------------------------
install_core_packages() {
    echo -e "\n\033[38;5;33m[3/6] Installing System Packages\033[0m"
    
    local base_packages=(
        nala bash-completion curl git
        xfce4 xfce4-terminal xfce4-whiskermenu-plugin
        mousepad ristretto tumbler
    )
    
    proot-distro login debian -- /bin/bash -c \
        "apt install -y ${base_packages[*]}"
}

#------------------------------------------------------------------------------
# USER MANAGEMENT
#------------------------------------------------------------------------------
configure_user() {
    echo -e "\n\033[38;5;33m[4/6] Creating User Account\033[0m"
    
    proot-distro login debian -- /bin/bash -c \
        "useradd -m -s /bin/bash $DEFAULT_USER && \
        echo '$DEFAULT_USER:$DEFAULT_PASS' | chpasswd && \
        usermod -aG sudo $DEFAULT_USER && \
        echo '$DEFAULT_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$DEFAULT_USER"
}

#------------------------------------------------------------------------------
# GRAPHICAL ENVIRONMENT SETUP
#------------------------------------------------------------------------------
setup_gui() {
    [ "$ENABLE_GUI" = true ] || return 0
    
    echo -e "\n\033[38;5;33m[5/6] Configuring Graphical Environment\033[0m"
    
    # Install Mesa Vulkan
    local mesa_pkg="mesa-vulkan-kgsl_${MESA_VERSION}_arm64.deb"
    wget -q "https://github.com/GiGiDKR/OhMyTermux/raw/1.0.0/src/$mesa_pkg" -P "$PKG_CACHE"
    proot-distro login debian -- dpkg -i "$PKG_CACHE/$mesa_pkg"
    
    # Theme configuration
    proot-distro login debian -- /bin/bash -c \
        "mkdir -p /usr/share/themes /usr/share/icons && \
        cp -r $PREFIX/share/themes/$THEME_NAME /usr/share/themes/ && \
        cp -r $PREFIX/share/icons/$ICON_THEME /usr/share/icons/ && \
        chown -R $DEFAULT_USER:$DEFAULT_USER /usr/share/themes /usr/share/icons"
}

#------------------------------------------------------------------------------
# FINALIZATION
#------------------------------------------------------------------------------
finalize_setup() {
    echo -e "\n\033[38;5;33m[6/6] Finalizing Installation\033[0m"
    
    # Create desktop shortcuts
    mkdir -p "$DEBIAN_ROOT/home/$DEFAULT_USER/Desktop"
    cat > "$DEBIAN_ROOT/home/$DEFAULT_USER/Desktop/Terminal.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
EOF

    # Set default wallpaper
    cp "$PREFIX/share/backgrounds/whitesur/$WALLPAPER_NAME.jpg" \
        "$DEBIAN_ROOT/usr/share/backgrounds/"

    echo -e "\n\033[38;5;82mInstallation complete!\033[0m"
    echo -e "Username: \033[1m$DEFAULT_USER\033[0m"
    echo -e "Password: \033[1m$DEFAULT_PASS\033[0m"
    echo -e "\nStart XFCE with: \033[1mproot-distro login debian -- xfce4-session\033[0m"
}

#------------------------------------------------------------------------------
# MAIN EXECUTION
#------------------------------------------------------------------------------
prepare_termux
setup_proot
install_core_packages
configure_user
setup_gui
finalize_setup
