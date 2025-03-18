#!/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
W="\033[0m"

# Configuration
STYLE=${1:-3}  # Default to macOS theme
BASE_URL="https://github.com/sabamdarif/termux-desktop/raw/setup-files/setup-files/xfce/look_"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"

# Icon Packs
ICON_PACKS=(
    "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.tar.gz"
    "https://github.com/numixproject/numix-icon-theme/archive/master.tar.gz"
    "https://github.com/keeferrourke/la-capitaine-icon-theme/archive/master.tar.gz"
    "https://github.com/vinceliuice/Tela-icon-theme/archive/master.tar.gz"
    "https://github.com/daniruiz/flat-remix/archive/master.tar.gz"
)

# macOS Wallpapers
MACOS_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
    "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
)

check_deps() {
    local deps=(wget tar)
    [ $STYLE -eq 5 ] && deps+=(eww xorg-xrdb git)
    
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${R}[!] Installing $dep...${W}"
            pkg install -y $dep
        fi
    done
}

install_icons() {
    echo -e "${C}[*] Installing icon packs...${W}"
    mkdir -p "$ICON_DIR"
    
    for pack in "${ICON_PACKS[@]}"; do
        name=$(basename "$pack" | cut -d'-' -f1)
        echo -e "${G}[+] Installing $name..."
        wget -q --show-progress "$pack" -O "$name.tar.gz"
        tar xzf "$name.tar.gz" -C "$ICON_DIR"
        rm "$name.tar.gz"
    done
    
    gtk-update-icon-cache -f -t "$ICON_DIR"/*
}

setup_wallpapers() {
    echo -e "${C}[*] Setting up wallpapers...${W}"
    mkdir -p "$WALLPAPER_DIR"
    
    # Theme wallpapers
    wget -q --show-progress "${BASE_URL}${STYLE}/wallpaper.tar.gz"
    tar xzf wallpaper.tar.gz -C "$WALLPAPER_DIR"
    rm wallpaper.tar.gz
    
    # macOS extras
    if [ $STYLE -eq 3 ]; then
        for url in "${MACOS_WALLPAPERS[@]}"; do
            wget -q --show-progress "$url" -P "$WALLPAPER_DIR"
        done
    fi
}

setup_cyberpunk() {
    echo -e "${C}[*] Configuring Cyberpunk...${W}"
    git clone https://github.com/sabamdarif/termux-cyberpunk-theme
    cp -r termux-cyberpunk-theme/* ~/.config/
    rm -rf termux-cyberpunk-theme
}

install_theme() {
    echo -e "${C}[*] Installing theme components...${W}"
    mkdir -p "$THEME_DIR"
    
    components=(icon theme)
    for component in "${components[@]}"; do
        wget -q --show-progress "${BASE_URL}${STYLE}/${component}.tar.gz"
        tar xzf "${component}.tar.gz" -C "$THEME_DIR"
        rm "${component}.tar.gz"
    done
    
    [ $STYLE -eq 5 ] && setup_cyberpunk
}

# Main installation function
main() {
    clear
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    XFCE Desktop Installation       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # System compatibility check
    if ! detect_termux; then
        echo -e "${YELLOW}Please ensure your system meets the requirements${NC}"
        exit 1
    fi

    # User confirmation
    echo -e "${GREEN}This will install XFCE native desktop in Termux${NC}"
    read -r -p $'\n${YELLOW}Press Enter to continue or Ctrl+C to cancel${NC}'

    # User input
    echo -n "Please enter username for proot installation: " > /dev/tty
    read username < /dev/tty

    # Repository and storage setup
    termux-change-repo || exit 1
    [ -d ~/storage ] || termux-setup-storage || exit 1

    # System upgrades
    pkg upgrade -y -o Dpkg::Options::="--force-confold" || exit 1

    # Core dependencies
    dependencies=('wget' 'proot-distro' 'x11-repo' 'tur-repo' 'pulseaudio' 'git')
    pkg install -y "${dependencies[@]}" -o Dpkg::Options::="--force-confold" || exit 1

    # Create directory structure
    mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/.fonts" "$HOME/.config" \
        "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/" "$HOME/.config/autostart/"

    # Install XFCE packages
    xfce_packages=('xfce4' 'xfce4-goodies' 'xfce4-pulseaudio-plugin' 'firefox' 'starship' 
                   'termux-x11-nightly' 'virglrenderer-android' 'mesa-vulkan-icd-freedreno-dri3'
                   'fastfetch' 'papirus-icon-theme' 'eza' 'bat')
    pkg install -y "${xfce_packages[@]}" -o Dpkg::Options::="--force-confold" || exit 1

    # Configure theming
    configure_theming

    # Set aliases and starship
    echo -e "\nalias ls='eza -lF --icons'\nalias cat='bat'\neval \"\$(starship init bash)\"" \
        >> $PREFIX/etc/bash.bashrc
    curl -o $HOME/.config/starship.toml https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/starship.toml
    sed -i "s/phoenixbyrd/$username/" $HOME/.config/starship.toml

    # Desktop utilities
    create_desktop_utilities
    setup_fonts
    configure_proot_environment
    setup_hardware_acceleration

    # Finalization
    termux-reload-settings
    echo -e "${GREEN}Installation complete! Use 'start' to launch your desktop environment.${NC}"
}

# Theming configuration function
configure_theming() {
    echo -e "\n${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Configuring XFCE Themes      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

    # Wallpaper setup
    wget -q https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/dark_waves.png
    mv dark_waves.png $PREFIX/share/backgrounds/xfce/

    # Theme installations
    install_whitesur_theme
    install_fluent_cursors

    # XFCE config files
    create_xsettings
    create_xfwm4_settings
    create_desktop_settings

    # GTK configuration
    mkdir -p $HOME/.config/gtk-3.0
    echo -e ".xfce4-panel {\n  border-top-left-radius: 10px;\n  border-top-right-radius: 10px;\n}" \
        > $HOME/.config/gtk-3.0/gtk.css

    # Terminal theming
    mkdir -p $HOME/.config/xfce4/terminal
    curl -s https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/terminalrc \
        > $HOME/.config/xfce4/terminal/terminalrc
}

# Helper functions for theming
install_whitesur_theme() {
    wget -q https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/2023-04-26.zip
    unzip -q 2023-04-26.zip
    tar -xf WhiteSur-gtk-theme-2023-04-26/release/WhiteSur-Dark-44-0.tar.xz
    mv WhiteSur-Dark/ $PREFIX/share/themes/
    rm -rf WhiteSur* 2023-04-26.zip
}

install_fluent_cursors() {
    wget -q https://github.com/vinceliuice/Fluent-icon-theme/archive/2023-02-01.zip
    unzip -q 2023-02-01.zip
    mv Fluent-icon-theme-2023-02-01/cursors/dist* $PREFIX/share/icons/
    rm -rf Fluent-icon-theme-2023-02-01 2023-02-01.zip
}

create_xsettings() {
    cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="dist-dark"/>
    <property name="CursorThemeSize" type="int" value="28"/>
  </property>
</channel>
EOF
}

create_xfwm4_settings() {
    cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="WhiteSur-Dark"/>
    <property name="title_alignment" type="string" value="center"/>
  </property>
</channel>
EOF
}

create_desktop_settings() {
    cat <<EOF > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorDexDisplay" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="$PREFIX/share/backgrounds/xfce/dark_waves.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
}

# Start installation
main
