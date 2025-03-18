#!/bin/bash

#########################################################################
#
# Complete Termux Theming Script
# Supports macOS Theme and Regular Styles
# Uses CDN for Reliable Downloads
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

# Configuration
current_path=$(pwd)
icons_folder="$HOME/.icons"
themes_folder="$HOME/.themes"
log_file="$HOME/theme_install.log"
de_name=$(ps -e | grep -E -i "xfce|openbox|mate|lxqt" | awk '{print $4}' | tr -d ' ' | head -1)
mac_theme=false

#########################################################################
# Core Utilities
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
    [ ! -d "$1" ] && mkdir -p "$1" && log_info "Created directory: $1"
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

function package_install() {
    echo -e "${C}[+] Installing packages: $1${W}"
    pkg install -y $1 2>>"$log_file" || log_error "Package install failed: $1"
}

#########################################################################
# Theme Functions
#########################################################################

function detect_de() {
    [ -z "$de_name" ] && log_error "No supported DE detected (XFCE/MATE/Openbox/LXQt)"
    log_info "Detected desktop environment: $de_name"
}

function install_fonts() {
    echo -e "${C}[+] Installing Fonts...${W}"
    check_and_create_directory "$HOME/.fonts"
    
    if $mac_theme; then
        download_and_extract \
            "https://cdn.jsdelivr.net/gh/supermarin/YosemiteSanFranciscoFont@master/fonts.tar.gz" \
            "$HOME/.fonts"
    else
        download_and_extract \
            "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/${de_name}/look_${style_answer}/font.tar.gz" \
            "$HOME/.fonts"
    fi
    
    fc-cache -f >/dev/null 2>&1
}

function configure_macos() {
    echo -e "${C}[+] Configuring macOS Layout...${W}"
    
    # Install dependencies
    package_install "plank feh rofi picom"
    
    # Dock configuration
    check_and_create_directory "$HOME/.config/plank"
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/macOS/dock.tar.gz" \
        "$HOME/.config/plank"

    # Window controls
    [[ "$de_name" == "xfce" ]] && \
        xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "CMH|"
}

function install_macos_theme() {
    echo -e "${C}[+] Installing macOS Components...${W}"
    
    # GTK Theme
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/B00merang-Project/macOS-Sierra@master/theme.tar.gz" \
        "$themes_folder"

    # Icons
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/keeferrourke/la-capitaine-icon-theme@master/icons.tar.gz" \
        "$HOME/.icons"

    # Wallpapers
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/macOS-backgrounds@main/wallpapers.tar.gz" \
        "$PREFIX/share/backgrounds/macOS"
}

function install_standard_theme() {
    echo -e "${C}[+] Installing Theme Components...${W}"
    
    # Common dependencies
    package_install "gnome-themes-extra gtk2-engines-murrine"
    
    # Wallpapers
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/${de_name}/look_${style_answer}/wallpaper.tar.gz" \
        "$PREFIX/share/backgrounds"

    # Icons
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/${de_name}/look_${style_answer}/icon.tar.gz" \
        "$icons_folder"

    # Theme
    download_and_extract \
        "https://cdn.jsdelivr.net/gh/sabamdarif/termux-desktop@setup-files/${de_name}/look_${style_answer}/theme.tar.gz" \
        "$themes_folder"
}

#########################################################################
# User Interface
#########################################################################

function select_theme() {
    banner
    echo -e "${Y}"
    echo "Available Themes:"
    echo "1.  Minimal Dark"
    echo "2.  Material Light"
    echo "3.  Nord Polar"
    echo "99. macOS Monterey"
    echo -e "${NC}"
    
    while true; do
        read -t 30 -rp "${C}Select theme (1-3/99): ${W}" style_answer || {
            echo -e "\n${R}Timeout, using default 1${W}"
            style_answer=1
            break
        }
        
        case $style_answer in
            99) mac_theme=true; style_name="macOS Monterey"; break ;;
            1|2|3) styles=("Minimal Dark" "Material Light" "Nord Polar")
                   style_name=${styles[$style_answer-1]}; break ;;
            *) echo -e "${R}Invalid selection!${W}";;
        esac
    done
}

#########################################################################
# Main Execution
#########################################################################

# Initial setup
pkg update -y && pkg upgrade -y
package_install "curl tar x11-repo"

# Installation process
{
    detect_de
    select_theme
    check_and_create_directory "$HOME/.config"
    
    if $mac_theme; then
        install_fonts
        configure_macos
        install_macos_theme
    else
        install_fonts
        install_standard_theme
    fi
    
    # Finalize
    [ "$de_name" == "xfce" ] && xfce4-panel -r
    echo -e "${G}[✓] Theme installed successfully!${W}"
    echo -e "${Y}Restart your desktop environment to apply changes.${W}"
    
} || {
    log_error "Installation failed"
}
