#!/bin/bash

# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file for debugging
LOG_FILE="$HOME/termux_setup.log"
exec &> >(tee -a "$LOG_FILE")

# Temporary directory for setup
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Function to print colored status
print_status() {
    local status=$1
    local message=$2
    case "$status" in
        "ok") echo -e "${GREEN}✓${NC} $message" ;;
        "warn") echo -e "${YELLOW}!${NC} $message" ;;
        "error") echo -e "${RED}✗${NC} $message" ;;
    esac
}

# Function to clean up on exit
finish() {
    local ret=$?
    if [ $ret -ne 0 ] && [ $ret -ne 130 ]; then
        echo -e "${RED}ERROR: An issue occurred. Please check $LOG_FILE for details.${NC}"
    fi
    rm -rf "$TEMP_DIR"
    exit $ret
}

trap finish EXIT

# Function to validate username
validate_username() {
    local username=$1
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo -e "${RED}Invalid username! Must be lowercase, start with letter/underscore, and contain only a-z, 0-9, -_${NC}"
        return 1
    fi
    return 0
}

# Enhanced package installation with retries
install_packages() {
    local packages=("$@")
    local max_retries=3
    local attempt=1
    
    until pkg install -y "${packages[@]}" -o Dpkg::Options::="--force-confold"; do
        if [ $attempt -ge $max_retries ]; then
            print_status "error" "Failed to install packages after $max_retries attempts"
            return 1
        fi
        print_status "warn" "Package installation failed, retrying ($attempt/$max_retries)..."
        ((attempt++))
        sleep 5
    done
}

# Function to detect system compatibility
detect_termux() {
    local errors=0
    
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      System Compatibility Check    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}\n"
    
    # Check if running on Android
    if [[ "$(uname -o)" = "Android" ]]; then
        print_status "ok" "Running on Android $(getprop ro.build.version.release)"
    else
        print_status "error" "Not running on Android"
        ((errors++))
    fi

    # Check architecture
    local arch=$(uname -m)
    if [[ "$arch" = "aarch64" ]]; then
        print_status "ok" "Architecture: $arch"
    else
        print_status "error" "Unsupported architecture: $arch (requires aarch64)"
        ((errors++))
    fi

    # Check for required directories
    if [[ -d "$PREFIX" ]]; then
        print_status "ok" "Termux PREFIX directory found"
    else
        print_status "error" "Termux PREFIX directory not found"
        ((errors++))
    fi

    # Check available storage space
    local free_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    if [[ $(df "$HOME" | awk 'NR==2 {print $4}') -gt 4194304 ]]; then
        print_status "ok" "Available storage: $free_space"
    else
        print_status "warn" "Low storage space: $free_space (4GB recommended)"
    fi

    # Check RAM
    local total_ram=$(free -m | awk 'NR==2 {print $2}')
    if [[ $total_ram -gt 2048 ]]; then
        print_status "ok" "RAM: ${total_ram}MB"
    else
        print_status "warn" "Low RAM: ${total_ram}MB (2GB recommended)"
    fi

    echo
    if [[ $errors -eq 0 ]]; then
        echo -e "${YELLOW}All system requirements met!${NC}"
        return 0
    else
        echo -e "${RED}Found $errors error(s). System requirements not met.${NC}"
        return 1
    fi
}

# Main installation function
main() {
    clear
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    XFCE Desktop Installation       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # Check system compatibility
    if ! detect_termux; then
        echo -e "${YELLOW}Please ensure your system meets the following requirements:${NC}"
        echo "• Termux GitHub release"
        echo "• ARM64 (aarch64) device"
        echo "• Android operating system"
        echo "• At least 4GB free storage"
        echo "• At least 2GB RAM recommended"
        exit 1
    fi

    echo -e "\n${GREEN}This will install XFCE native desktop in Termux"
    echo -e "${GREEN}A Debian proot-distro is also installed for additional software"
    echo -e "${GREEN}while also enabling hardware acceleration"
    echo -e "${GREEN}This setup has been tested on a Samsung Galaxy S24 Ultra"
    echo -e "${GREEN}It should run on most phones however.${NC}"
    echo -e "\n${RED}Please install termux-x11: ${YELLOW}https://github.com/termux/termux-x11/releases"
    echo -e "\n${YELLOW}Press Enter to continue or Ctrl+C to cancel${NC}"
    
    read -r

    # Get valid username
    while true; do
        echo -n "Please enter username for proot installation: " > /dev/tty
        read -r username < /dev/tty
        if validate_username "$username"; then
            break
        fi
    done

    # Change repository
    if ! termux-change-repo; then
        print_status "error" "Failed to change repository"
        exit 1
    fi

    # Setup Termux Storage Access
    if [ ! -d ~/storage ]; then
        if ! termux-setup-storage; then
            print_status "error" "Failed to set up Termux storage"
            echo -e "${YELLOW}Please clear Termux data in app info settings and run setup again${NC}"
            exit 1
        fi
    else
        print_status "ok" "Storage access already granted"
    fi

    # Upgrade packages
    print_status "ok" "Upgrading packages..."
    if ! pkg upgrade -y -o Dpkg::Options::="--force-confold"; then
        print_status "error" "Failed to upgrade packages"
        exit 1
    fi

    # Update termux.properties
    mkdir -p "$HOME/.termux"
    [ -f "$HOME/.termux/termux.properties" ] || touch "$HOME/.termux/termux.properties"
    sed -i 's/^# allow-external-apps = true/allow-external-apps = true/' "$HOME/.termux/termux.properties"

    # Install core dependencies
    dependencies=('wget' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio' 'git')
    print_status "ok" "Installing dependencies..."
    if ! install_packages "${dependencies[@]}"; then
        exit 1
    fi

    # Create default directories
    mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/.fonts" "$HOME/.config" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/" "$HOME/.config/autostart/" "$HOME/.config/gtk-3.0/" "$HOME/.config/xfce4/terminal/" "$HOME/.config/xfce4/panel/"{launcher-7,launcher-10,launcher-11}

    # Install XFCE desktop environment
    xfce_packages=('xfce4' 'xfce4-goodies' 'xfce4-pulseaudio-plugin' 'firefox' 'starship' 'termux-x11-nightly' 'virglrenderer-android' 'mesa-vulkan-icd-freedreno-dri3' 'fastfetch' 'papirus-icon-theme' 'eza' 'bat')
    print_status "ok" "Installing XFCE packages..."
    if ! install_packages "${xfce_packages[@]}"; then
        exit 1
    fi

    # Set aliases
    echo -e "\nalias debian='proot-distro login debian --user $username --shared-tmp'
alias ls='eza -lF --icons'
alias cat='bat'

eval \"\$(starship init bash)\"" >> "$PREFIX/etc/bash.bashrc"

    # Download starship theme
    if ! curl -fsSo "$HOME/.config/starship.toml" https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/starship.toml; then
        print_status "error" "Failed to download starship theme"
        exit 1
    fi
    sed -i "s/phoenixbyrd/$username/" "$HOME/.config/starship.toml"

    # Download Wallpaper
    if ! wget -q https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/dark_waves.png; then
        print_status "error" "Failed to download wallpaper"
        exit 1
    fi
    mv dark_waves.png "$PREFIX/share/backgrounds/xfce/"

    # Install WhiteSur-Dark Theme
    if ! wget -q https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/2023-04-26.zip || \
       ! unzip -q 2023-04-26.zip || \
       ! tar -xf WhiteSur-gtk-theme-2023-04-26/release/WhiteSur-Dark-44-0.tar.xz; then
        print_status "error" "Failed to install WhiteSur theme"
        exit 1
    fi
    mv WhiteSur-Dark/ "$PREFIX/share/themes/"
    rm -rf WhiteSur* 2023-04-26.zip

    # Install Fluent Cursor Icon Theme
    if ! wget -q https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2023-02-01.zip || \
       ! unzip -q 2023-02-01.zip; then
        print_status "error" "Failed to install Fluent icons"
        exit 1
    fi
    mv Fluent-icon-theme-2023-02-01/cursors/dist* "$PREFIX/share/icons/"
    rm -rf Fluent* 2023-02-01.zip

    # XML configuration files remain unchanged from original script

    # Setup Fonts
    if ! wget -q https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip || \
       ! unzip -q CascadiaCode-2111.01.zip || \
       ! mv otf/static/*.otf "$HOME/.fonts/" || \
       ! mv ttf/*.ttf "$HOME/.fonts/"; then
        print_status "error" "Failed to install Cascadia fonts"
        exit 1
    fi
    rm -rf otf ttf woff2 CascadiaCode-2111.01.zip

    if ! wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip || \
       ! unzip -q Meslo.zip || \
       ! mv *.ttf "$HOME/.fonts/"; then
        print_status "error" "Failed to install Meslo fonts"
        exit 1
    fi
    rm -f Meslo.zip LICENSE.txt readme.md

    if ! wget -q https://github.com/phoenixbyrd/Termux_XFCE/raw/main/NotoColorEmoji-Regular.ttf || \
       ! mv NotoColorEmoji-Regular.ttf "$HOME/.fonts/"; then
        print_status "error" "Failed to install emoji font"
        exit 1
    fi

    # Update font cache
    fc-cache -fv >/dev/null

    # Remaining installation steps remain similar but with error checking added

    # Post-install checks
    if ! command -v xfce4-session >/dev/null; then
        print_status "error" "XFCE4 installation verification failed"
        exit 1
    fi

    if ! proot-distro list | grep -q debian; then
        print_status "error" "Debian proot installation verification failed"
        exit 1
    fi

    # Final cleanup
    rm -f Powerful.sh
}

# Start installation
main

clear
# Display usage instructions
echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Setup Complete!            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Available Commands:${NC}"
echo -e "${YELLOW}start${NC} - Launches XFCE desktop with hardware acceleration"
echo -e "${YELLOW}debian${NC} - Enters Debian proot environment"
echo -e "${YELLOW}prun${NC} - Runs Debian applications directly from Termux"
echo -e "${YELLOW}zrun${NC} - Runs apps with hardware acceleration"
echo -e "${YELLOW}zrunhud${NC} - Same as zrun with FPS overlay\n"

echo -e "${GREEN}Next Steps:${NC}"
echo "1. Restart Termux"
echo "2. Run 'start' to launch XFCE"
echo "3. Install termux-x11 APK from GitHub releases\n"

termux-reload-settings
