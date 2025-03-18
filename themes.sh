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

# System Configuration
LOG_FILE="$HOME/termux_setup.log"
TEMP_DIR=$(mktemp -d)
exec 2>>"$LOG_FILE"

# ========================
# Core Functions
# ========================

print_status() {
    local status=$1
    local message=$2
    case $status in
        "ok") echo -e "${GREEN}✓${NC} $message" ;;
        "warn") echo -e "${YELLOW}!${NC} $message" ;;
        *) echo -e "${RED}✗${NC} $message" ;;
    esac
}

detect_termux() {
    local errors=0
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      System Compatibility Check    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    [[ "$(uname -o)" = "Android" ]] || { print_status "error" "Not running on Android"; ((errors++)); }
    [[ "$(uname -m)" = "aarch64" ]] || { print_status "error" "Unsupported architecture"; ((errors++)); }
    [[ -d "$PREFIX" ]] || { print_status "error" "Termux PREFIX missing"; ((errors++)); }

    return $errors
}

# ========================
# WhiteSur-Dark Implementation
# ========================

install_whitesur_theme() {
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     WhiteSur-Dark Theme Setup      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # GTK Theme
    print_status "ok" "Installing WhiteSur-Dark GTK theme"
    wget -q https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/2023-04-26.zip
    unzip -q 2023-04-26.zip
    tar -xf WhiteSur-gtk-theme-2023-04-26/release/WhiteSur-Dark-44-0.tar.xz
    mv WhiteSur-Dark/ $PREFIX/share/themes/
    
    # Icons
    print_status "ok" "Installing WhiteSur-Dark icons"
    wget -q https://github.com/vinceliuice/WhiteSur-icon-theme/archive/2023-11-28.tar.gz
    tar -zxf 2023-11-28.tar.gz
    mv WhiteSur-icon-theme-2023-11-28/WhiteSur-Dark $HOME/.icons/
    
    # Wallpaper
    print_status "ok" "Setting default wallpaper"
    mkdir -p $PREFIX/share/backgrounds/xfce
    wget -q -O $PREFIX/share/backgrounds/xfce/WhiteSur-Dark.png \
        https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/backgrounds/monterey/WhiteSur_Dark.png

    # Cleanup
    rm -rf WhiteSur-* 2023-*
}

configure_whitesur() {
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Applying WhiteSur-Dark Config   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml

    # XSettings
    cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="WhiteSur-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="CursorThemeSize" type="int" value="24"/>
  </property>
</channel>
EOF

    # Update icon cache
    print_status "ok" "Updating icon cache"
    gtk-update-icon-cache -f -t $HOME/.icons/WhiteSur-Dark
}

# ========================
# Theme Manager (Optional)
# ========================

install_theme_manager() {
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Installing Theme Manager       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    cat <<'EOF' > $PREFIX/bin/xfce-themes
#!/bin/bash

# Theme Manager Script
# (Reduced version focusing on WhiteSur compatibility)

R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
NC="\033[0m"

show_menu() {
    clear
    echo -e "${B}┌──────────────────────────┐"
    echo -e "│ WhiteSur Theme Manager  │"
    echo -e "└──────────────────────────┘${NC}"
    echo -e "1. Reset to WhiteSur Defaults"
    echo -e "2. Change Wallpaper"
    echo -e "3. Exit"
}

reset_defaults() {
    rm -rf ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
    cp /data/data/com.termux/files/usr/share/whitesur-configs/* ~/.config/xfce4/xfconf/xfce-perchannel-xml/
    echo -e "${G}✓ Reset to WhiteSur defaults!${NC}"
    sleep 2
}

main() {
    while true; do
        show_menu
        read -p "Select option: " choice
        case $choice in
            1) reset_defaults ;;
            2) echo -e "${Y}Feature not implemented${NC}"; sleep 1 ;;
            3) exit 0 ;;
            *) echo -e "${R}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

main
EOF

    chmod +x $PREFIX/bin/xfce-themes
    print_status "ok" "Theme manager installed"

    # Desktop shortcut
    cat <<'EOF' > $HOME/Desktop/Theme-Manager.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Theme Manager
Comment=WhiteSur Theme Customizer
Exec=xfce-themes
Icon=preferences-desktop-theme
Categories=Settings;
EOF
    chmod +x $HOME/Desktop/Theme-Manager.desktop
}

# ========================
# Main Installation Flow
# ========================

main() {
    clear
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Termux XFCE WhiteSur Installer  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # System checks
    detect_termux || {
        echo -e "${RED}System requirements not met. Exiting.${NC}"
        exit 1
    }

    # User confirmation
    read -p $'\n'"${YELLOW}Proceed with installation? [y/N] ${NC}" -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0

    # Core packages
    print_status "ok" "Updating packages"
    pkg upgrade -y
    
    print_status "ok" "Installing core dependencies"
    pkg install -y wget proot-distro x11-repo tur-repo \
        xfce4 xfce4-goodies firefox termux-x11-nightly

    # WhiteSur installation
    install_whitesur_theme
    configure_whitesur

    # Optional components
    print_status "ok" "Installing theme manager"
    install_theme_manager

    # Final setup
    termux-reload-settings
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo -e "Run ${YELLOW}start${NC} to launch XFCE"
    echo -e "Run ${YELLOW}xfce-themes${NC} for customization"
}

# Cleanup and execution
trap 'rm -rf "$TEMP_DIR"' EXIT
main
