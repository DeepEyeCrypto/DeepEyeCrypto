#!/bin/bash

#########################################################################
#
# Complete macOS Theming Script for Termux
# Includes Dependency Management and Error Handling
#
#########################################################################

# Color Variables
R='\033[1;31m'
C='\033[1;36m'
Y='\033[1;33m'
G='\033[1;32m'
W='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration Variables
current_path=$(pwd)
icons_folder="$HOME/.icons"
themes_folder="$HOME/.themes"
log_file="$HOME/theme_install.log"
de_name=$(ps -e | grep -E -i "xfce|openbox|mate|lxqt" | awk '{print $4}' | tr -d ' ' | head -1)
mac_theme=false

#########################################################################
# Core Utility Functions
#########################################################################

function banner() {
    clear
    echo -e "${Y}"
    echo "  ___  _____  __  _______  ___  ____  "
    echo " / _ \/ __/ |/ / / __/ _ \/ _ \/ __/  "
    echo "/ , _/ _//    / / _// , _/ ___/ _/    "
    echo "\_/_/___/_/|_/ /___/_/|_/_/  /___/    "
    echo -e "${NC}"
}

function log_info() {
    echo -e "${C}[INFO]${W} $1 - ${2:-}" | tee -a "$log_file"
}

function log_error() {
    echo -e "${R}[ERROR]${W} $1 - ${2:-}" | tee -a "$log_file"
    exit 1
}

function check_and_create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1" || log_error "Failed to create directory: $1"
        log_info "Created directory: $1"
    fi
}

function download_and_extract() {
    local url="$1"
    local target_dir="$2"
    local flags="$3"
    
    check_and_create_directory "$target_dir"
    echo -e "${C}[+] Downloading ${url##*/}...${W}"
    
    if ! curl -L "$url" | tar xz $flags -C "$target_dir" 2>>"$log_file"; then
        log_error "Failed to download/extract: $url"
    fi
}

function package_install_and_check() {
    echo -e "${C}[+] Installing packages: $1${W}"
    pkg install -y $1 2>>"$log_file" || log_error "Package installation failed: $1"
}

#########################################################################
# Theme Management Functions
#########################################################################

function detect_de() {
    [ -z "$de_name" ] && log_error "No supported DE detected (XFCE/MATE/Openbox/LXQt)"
    log_info "Detected desktop environment: $de_name"
}

function install_font_for_style() {
    local style_number="$1"
    echo -e "${C}[+] Installing Fonts...${W}"
    check_and_create_directory "$HOME/.fonts"
    
    if $mac_theme; then
        download_and_extract \
            "https://github.com/supermarin/YosemiteSanFranciscoFont/archive/refs/heads/master.tar.gz" \
            "$HOME/.fonts" \
            "--wildcards *.ttf"
    else
        download_and_extract \
            "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/${de_name}/look_${style_number}/font.tar.gz" \
            "$HOME/.fonts"
    fi
    
    fc-cache -f >/dev/null 2>&1
}

function configure_macos_layout() {
    echo -e "${C}[+] Configuring macOS Layout...${W}"
    check_and_create_directory "$HOME/.config/plank"
    
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/macOS/dock.tar.gz" \
        "$HOME/.config/plank"

    [[ "$de_name" == "xfce" ]] && \
        xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "CMH|"
}

function install_macos_theme() {
    echo -e "${C}[+] Installing macOS Theme Components...${W}"
    
    # GTK Theme
    download_and_extract \
        "https://github.com/B00merang-Project/macOS-Sierra/archive/refs/heads/master.tar.gz" \
        "$themes_folder" \
        "--strip-components=1"
        
    # Wallpapers
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/macOS-backgrounds@main/wallpapers.tar.gz" \
        "$PREFIX/share/backgrounds/macOS"

    # Icon Theme
    download_and_extract \
        "https://github.com/keeferrourke/la-capitaine-icon-theme/archive/refs/heads/master.tar.gz" \
        "$HOME/.icons" \
        "--strip-components=1 --wildcards */La-Capitaine/*"
}

function theme_installer() {
    detect_de
    banner
    
    if $mac_theme; then
        package_install_and_check "plank feh rofi picom"
        install_macos_theme
        configure_macos_layout
    else
        echo -e "${C}[+] Installing Standard Theme Components...${W}"
        package_install_and_check "gnome-themes-extra gtk2-engines-murrine"
        
        # Wallpaper setup
        download_and_extract \
            "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/${de_name}/look_${style_answer}/wallpaper.tar.gz" \
            "$PREFIX/share/backgrounds"
    fi

    # Final configuration
    echo -e "${C}[+] Applying Final Configuration...${W}"
    [ "$de_name" == "xfce" ] && xfce4-panel -r
}

#########################################################################
# User Interaction
#########################################################################

function theme_selection() {
    banner
    echo -e "${Y}"
    echo "Available Themes:"
    echo "1.  Minimal Dark"
    echo "2.  Material Light"
    echo "3.  Nord Polar"
    echo "99. macOS Monterey"
    echo -e "${NC}"
    
    while true; do
        read -rp "${C}Select theme (1-3/99): ${W}" style_answer
        case $style_answer in
            99) mac_theme=true; style_name="macOS Monterey"; break ;;
            1|2|3) style_name=$(sed -n "${style_answer}p" <<< "Minimal Dark,Material Light,Nord Polar" | cut -d',' -f1); break ;;
            *) echo -e "${R}Invalid selection!${W}";;
        esac
    done
}

#########################################################################
# Main Execution
#########################################################################

# Initial setup
pkg update -y && pkg upgrade -y
pkg install -y curl tar x11-repo

# Start installation
{
    theme_selection
    check_and_create_directory "$HOME/.config"
    install_font_for_style "$style_answer"
    theme_installer
    echo -e "${G}[✓] Theme installation completed successfully!${W}"
} || {
    log_error "Main installation process failed"
}

echo -e "${Y}Please restart your desktop environment to apply changes.${W}"
