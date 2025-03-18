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
exec 2>>"$LOG_FILE"

# Temporary directory for setup
TEMP_DIR=$(mktemp -d)

# ========================
# Core XFCE Installation
# ========================

print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}!${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
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

configure_theming() {
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     WhiteSur-Dark Theme Setup      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # Install WhiteSur-Dark
    wget -q https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/2023-04-26.zip
    unzip -q 2023-04-26.zip
    tar -xf WhiteSur-gtk-theme-2023-04-26/release/WhiteSur-Dark-44-0.tar.xz
    mv WhiteSur-Dark/ $PREFIX/share/themes/
    rm -rf WhiteSur* 2023-04-26.zip

    # Apply theme configurations
    mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/
    cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
  </property>
</channel>
EOF

    # Set default wallpaper
    wget -q -O $PREFIX/share/backgrounds/xfce/WhiteSur-Dark.png \
        https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/backgrounds/monterey/WhiteSur_Dark.png
}

# ========================
# Theme Manager Installation
# ========================

install_theme_manager() {
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Installing Theme Manager       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    cat <<'EOF' > $PREFIX/bin/xfce-themes
#!/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
W="\033[0m"

BASE_URL="https://github.com/sabamdarif/termux-desktop/raw/setup-files/setup-files/xfce/look_"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"

ICON_PACKS=(
    "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.tar.gz"
    "https://github.com/numixproject/numix-icon-theme/archive/master.tar.gz"
    "https://github.com/keeferrourke/la-capitaine-icon-theme/archive/master.tar.gz"
    "https://github.com/vinceliuice/Tela-icon-theme/archive/master.tar.gz"
    "https://github.com/daniruiz/flat-remix/archive/master.tar.gz"
)

check_deps() {
    local deps=(wget tar)
    [ $STYLE -eq 5 ] && deps+=(eww xorg-xrdb git)
    for dep in "${deps[@]}"; do
        command -v $dep >/dev/null || pkg install -y $dep
    done
}

install_icons() {
    mkdir -p "$ICON_DIR"
    for pack in "${ICON_PACKS[@]}"; do
        name=$(basename "$pack" | cut -d'-' -f1)
        wget -q --show-progress "$pack" -O "$name.tar.gz"
        tar xzf "$name.tar.gz" -C "$ICON_DIR" && rm "$name.tar.gz"
    done
    gtk-update-icon-cache -f -t "$ICON_DIR"/*
}

setup_wallpapers() {
    mkdir -p "$WALLPAPER_DIR"
    wget -q --show-progress "${BASE_URL}${STYLE}/wallpaper.tar.gz"
    tar xzf wallpaper.tar.gz -C "$WALLPAPER_DIR" && rm wallpaper.tar.gz
}

setup_cyberpunk() {
    git clone https://github.com/sabamdarif/termux-cyberpunk-theme
    cp -r termux-cyberpunk-theme/* ~/.config/
    rm -rf termux-cyberpunk-theme
}

main() {
    clear
    echo -e "${C}┌──────────────────────────┐"
    echo -e "│ Termux XFCE Theme Manager │"
    echo -e "└──────────────────────────┘${W}"
    
    STYLE=${1:-3}
    check_deps
    install_icons
    setup_wallpapers
    
    [ $STYLE -eq 5 ] && setup_cyberpunk
    
    echo -e "\n${C}[√] Theme Changed!"
    echo -e "${Y}Restart XFCE to apply changes${W}"
}

main "$@"
EOF

    chmod +x $PREFIX/bin/xfce-themes
    print_status "ok" "Theme manager installed"

    # Create desktop shortcut
    cat <<'EOF' > $HOME/Desktop/Theme-Manager.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Theme Manager
Comment=Customize XFCE appearance
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
    echo -e "${BLUE}║    XFCE Desktop Installation       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # System checks
    detect_termux || {
        echo -e "${RED}System requirements not met. Exiting.${NC}"
        exit 1
    }

    # Core packages
    pkg upgrade -y
    pkg install -y wget proot-distro x11-repo tur-repo pulseaudio git \
        xfce4 xfce4-goodies firefox termux-x11-nightly virglrenderer-android

    # Theming
    configure_theming
    install_theme_manager

    # Final setup
    termux-reload-settings
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo -e "Run ${YELLOW}start${NC} to launch XFCE"
    echo -e "Run ${YELLOW}xfce-themes${NC} to customize appearance"
}

# Cleanup and execution
trap 'rm -rf "$TEMP_DIR"' EXIT
main
