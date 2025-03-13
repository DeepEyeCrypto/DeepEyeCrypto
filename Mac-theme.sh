#!/data/data/com.termux/files/usr/bin/bash

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
WALLPAPER_DIR="$PREFIX/share/backgrounds"
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

initial_setup() {
    echo -e "${C}[*] Starting initial setup...${W}"
    
    # Update packages
    echo -e "${G}[+] Updating packages...${W}"
    pkg update -y && pkg upgrade -y
    
    # Setup storage
    echo -e "${G}[+] Setting up storage...${W}"
    termux-setup-storage
    echo -e "${Y}[!] Please allow storage permission when prompted!${W}"
    
    # Install X11 and core components
    echo -e "${G}[+] Installing X11 components...${W}"
    pkg install x11-repo -y
    pkg install termux-x11-nightly -y
    pkg install pulseaudio -y
    
    # Install desktop environment
    echo -e "${G}[+] Installing XFCE4...${W}"
    pkg install xfce4 -y
    
    # Install additional software
    echo -e "${G}[+] Installing applications...${W}"
    pkg install tur-repo -y
    pkg install firefox chromium code-oss git wget -y
    
    # Install theme dependencies
    echo -e "${G}[+] Installing theme dependencies...${W}"
    pkg install zsh -y
}

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

final_steps() {
    echo -e "${C}[*] Finalizing setup...${W}"
    cd ~
    wget -q --show-progress https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh
    chmod +x DeepEyeCrypto.sh
    echo -e "${Y}[!] Warning: About to run external script DeepEyeCrypto.sh${W}"
    bash ~/DeepEyeCrypto.sh
}

main() {
    clear
    echo -e "${C}┌──────────────────────────────────┐"
    echo -e "│ Termux XFCE Complete Setup Script │"
    echo -e "└──────────────────────────────────┘${W}"
    
    initial_setup
    check_deps
    
    # Set Zsh as default shell
    if command -v zsh &>/dev/null; then
        echo -e "${C}[*] Configuring Zsh...${W}"
        chsh -s zsh 2>/dev/null || echo -e "${R}Failed to set Zsh as default shell.${W}"
    fi
    
    install_icons
    setup_wallpapers
    install_theme
    final_steps
    
    echo -e "\n${C}[√] Installation Complete!"
    echo -e "${Y}System components:"
    echo -e " - XFCE4 Desktop Environment"
    echo -e " - Firefox, Chromium, and Code-OSS"
    echo -e " - Termux X11 and PulseAudio"
    echo -e "\nTheme components:"
    echo -e " - Selected theme: ${THEME_DIR}/xfce-look-${STYLE}"
    echo -e " - Icon packs: ${ICON_DIR}"
    echo -e " - Wallpapers: ${WALLPAPER_DIR}"
    echo -e " - Zsh configured as default shell"
    echo -e "\n${R}Note: Restart Termux session for all changes to take effect!${W}"
}

main
