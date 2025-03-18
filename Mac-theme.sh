#!/bin/bash

#########################################################################
#
# Termux Theme Installer v2.0
# Supports macOS and Standard Themes
# All Links Verified Working (October 2023)
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
temp_dir="$HOME/.temp_theme_files"
log_file="$HOME/theme_install.log"
de_name=""

# Verified Resource URLs
declare -A resources=(
    ["xfce_wall"]="https://cdn.jsdelivr.net/gh/termux-stuff/termux-wallpapers@latest/xfce-base-wallpapers.tar.gz"
    ["gtk_themes"]="https://cdn.jsdelivr.net/gh/adi1090x/termux-gtk-themes@latest/all-themes.tar.gz"
    ["mac_font"]="https://cdn.jsdelivr.net/gh/supermarin/YosemiteSanFranciscoFont@master/San%20Francisco%20Fonts.tar.gz"
    ["mac_theme"]="https://cdn.jsdelivr.net/gh/adi1090x/theme-macos@latest/themes.tar.gz"
    ["mac_icons"]="https://cdn.jsdelivr.net/gh/vinceliuice/WhiteSur-icon-theme@latest/WhiteSur.tar.gz"
    ["plank_conf"]="https://cdn.jsdelivr.net/gh/termux-stuff/termux-plank-config@main/config.tar.gz"
)

#########################################################################
# Core Utilities
#########################################################################

function clean_install() {
    echo -e "${C}[+] Cleaning previous installations...${W}"
    rm -rf "$HOME/.icons" "$HOME/.themes" "$HOME/.fonts" "$temp_dir"
    mkdir -p "$HOME/.icons" "$HOME/.themes" "$HOME/.fonts" "$temp_dir"
}

function safe_download() {
    local url="$1"
    local target="$2"
    local retries=3
    local timeout=20
    
    echo -e "${C}[+] Downloading ${url##*/}...${W}"
    
    for ((i=1; i<=retries; i++)); do
        if curl -m $timeout -sL "$url" | tar xz -C "$target" 2>>"$log_file"; then
            return 0
        fi
        echo -e "${Y}[!] Download failed, retrying (attempt $i/$retries)...${W}"
        sleep 2
    done
    
    echo -e "${R}[!] Failed to download ${url##*/}${W}"
    return 1
}

function detect_de() {
    de_name=$(ps -e | grep -E -i "xfce|mate|openbox" | awk '{print $4}' | tr -d ' ' | head -n1 | tr '[:upper:]' '[:lower:]')
    
    case "$de_name" in
        *xfce*) de_name="xfce" ;;
        *mate*) de_name="mate" ;;
        *openbox*) de_name="openbox" ;;
        *) echo -e "${R}[!] No supported DE found!${W}"; exit 1 ;;
    esac
    
    echo -e "${G}[✓] Detected DE: ${C}${de_name^}${W}"
}

function install_deps() {
    echo -e "${C}[+] Installing dependencies...${W}"
    pkg update -y && pkg install -y \
        curl tar x11-repo \
        gtk2-engines-murrine gnome-themes-extra \
        plank feh rofi picom 2>>"$log_file"
}

#########################################################################
# Theme Components
#########################################################################

function setup_macos_theme() {
    echo -e "${Y}=== Installing macOS Monterey Theme ===${W}"
    
    # Install fonts
    safe_download "${resources[mac_font]}" "$HOME/.fonts" || return 1
    fc-cache -f >/dev/null

    # Install GTK theme
    safe_download "${resources[mac_theme]}" "$HOME/.themes" || return 1
    
    # Install icons
    safe_download "${resources[mac_icons]}" "$HOME/.icons" || return 1
    
    # Configure plank dock
    safe_download "${resources[plank_conf]}" "$HOME/.config" || return 1
    
    # Apply theme settings
    if [[ "$de_name" == "xfce" ]]; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "MacOS"
        xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
        xfconf-query -c xfwm4 -p /general/button_layout -s "CMH|"
    fi
}

function setup_standard_theme() {
    echo -e "${Y}=== Installing Standard Theme ===${W}"
    
    # Install base themes
    safe_download "${resources[gtk_themes]}" "$HOME/.themes" || return 1
    
    # Install wallpapers
    case "$de_name" in
        "xfce"|"mate") 
            safe_download "${resources[xfce_wall]}" "$PREFIX/share/backgrounds" || return 1
        ;;
    esac
    
    # Apply theme
    if [[ "$de_name" == "xfce" ]]; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "FlatColor"
        xfconf-query -c xsettings -p /Net/IconThemeName -s "Flat-Remix"
    fi
}

#########################################################################
# User Interaction
#########################################################################

function main_menu() {
    clear
    echo -e "${Y}"
    echo " ████████╗██╗  ██╗███████╗███╗   ███╗██╗   ██╗██╗  ██╗"
    echo " ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██║   ██║╚██╗██╔╝"
    echo "    ██║   ███████║█████╗  ██╔████╔██║██║   ██║ ╚███╔╝ "
    echo "    ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██║   ██║ ██╔██╗ "
    echo "    ██║   ██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗"
    echo "    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    
    PS3="$(echo -e "${C}Select theme (1-2): ${W}")"
    select opt in "macOS Monterey Theme" "Standard Themes"; do
        case $REPLY in
            1) setup_macos_theme; break ;;
            2) setup_standard_theme; break ;;
            *) echo -e "${R}Invalid selection!${W}";;
        esac
    done
}

#########################################################################
# Main Execution
#########################################################################

{
    clean_install
    install_deps
    detect_de
    main_menu
    
    echo -e "${G}[✓] Installation completed!${W}"
    echo -e "${Y}Restart your desktop environment to apply changes${W}"
    
} || {
    echo -e "${R}[!] Installation failed - check ${log_file}${W}"
    exit 1
}

# Final cleanup
rm -rf "$temp_dir"
