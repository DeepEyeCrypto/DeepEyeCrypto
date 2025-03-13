#!/data/data/com.termux/files/usr/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
W="\033[0m"

# Configuration
WALLPAPER_DIR="$PREFIX/share/backgrounds"
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"
APPSTORE_DIR="$PREFIX/opt/appstore"
ZSHRC_FILE="$HOME/.zshrc"

# Theme Packages
THEME_PACKS=(
    [2]="https://github.com/nana-4/materia-theme/releases/download/v2023-12-06/materia-dark.tar.xz"    # Modern Dark
    [3]="https://github.com/sabamdarif/termux-desktop/raw/setup-files/setup-files/xfce/look_3/theme.tar.gz"       # macOS
    [5]="https://github.com/sabamdarif/termux-desktop/raw/setup-files/setup-files/xfce/look_5/theme.tar.gz"       # Cyberpunk
    [6]="https://github.com/vinceliuice/WhiteSur-gtk-theme/releases/download/2.0.0/WhiteSur-Dark.tar.xz"         # WhiteSur Dark
)

# Icon Packs
ICON_PACKS=(
    "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.tar.gz"
    "https://github.com/numixproject/numix-icon-theme/archive/master.tar.gz"
    "https://github.com/keeferrourke/la-capitaine-icon-theme/archive/master.tar.gz"
)

# Wallpaper URLs
MODERN_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/abstract-dark-3840x2160-12465.jpg"
    "https://4kwallpapers.com/images/wallpapers/minimalism-dark-abstract-7680x4320-12157.jpg"
)
MACOS_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
)
CYBER_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/cyberpunk-edgerunners-cityscape-neon-lights-3840x2160-10018.jpg"
)

check_deps() {
    local deps=(wget tar xz-utils python git)
    [ $STYLE -eq 5 ] && deps+=(eww xorg-xrdb)
    deps+=(zsh curl)
    
    echo -e "${C}[*] Checking dependencies...${W}"
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${G}[+] Installing $dep...${W}"
            pkg install -y $dep
        fi
    done

    if ! pip show pygobject >/dev/null 2>&1; then
        echo -e "${G}[+] Installing Python dependencies...${W}"
        pip install pygobject pillow
    fi
}

install_zsh() {
    echo -e "${C}[*] Setting up Zsh...${W}"
    
    if ! command -v zsh &> /dev/null; then
        pkg install -y zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    cat > "$ZSHRC_FILE" <<EOL
# Aliases
alias themes='xfce4-appearance-settings'
alias iconthemes='cd $ICON_DIR && ls'
alias wallpapers='cd $WALLPAPER_DIR && ls'
alias appstore='python $APPSTORE_DIR/src/gtk_app_store.py'

# Oh My Zsh
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-syntax-highlighting)
source \$ZSH/oh-my-zsh.sh
EOL

    if [ "$SHELL" != "/data/data/com.termux/files/usr/bin/zsh" ]; then
        chsh -s zsh
    fi
}

install_icons() {
    echo -e "${C}[*] Installing icon packs...${W}"
    mkdir -p "$ICON_DIR"
    
    for pack in "${ICON_PACKS[@]}"; do
        name=$(basename "$pack" | cut -d'-' -f1)
        echo -e "${G}[+] Installing $name icons..."
        wget -q --show-progress "$pack" -O "$name.tar.gz"
        tar xzf "$name.tar.gz" -C "$ICON_DIR"
        rm "$name.tar.gz"
    done
    
    gtk-update-icon-cache -f -t "$ICON_DIR"/*
}

setup_wallpapers() {
    echo -e "${C}[*] Configuring wallpapers...${W}"
    mkdir -p "$WALLPAPER_DIR"
    
    case $STYLE in
        2)  # Modern Dark
            for url in "${MODERN_WALLPAPERS[@]}"; do
                wget -q --show-progress "$url" -P "$WALLPAPER_DIR"
            done
            ;;
        3)  # macOS
            for url in "${MACOS_WALLPAPERS[@]}"; do
                wget -q --show-progress "$url" -P "$WALLPAPER_DIR"
            done
            ;;
        5)  # Cyberpunk
            for url in "${CYBER_WALLPAPERS[@]}"; do
                wget -q --show-progress "$url" -P "$WALLPAPER_DIR"
            done
            ;;
        6)  # WhiteSur
            wget -q --show-progress "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/master/backgrounds/monterey/WhiteSur-monterey.png" -P "$WALLPAPER_DIR"
            ;;
    esac
}

install_theme() {
    echo -e "${C}[*] Installing theme...${W}"
    mkdir -p "$THEME_DIR"
    
    case $STYLE in
        2)  # Modern Dark
            echo -e "${G}[+] Installing Materia Dark...${W}"
            wget -q --show-progress "${THEME_PACKS[2]}" -O materia-dark.tar.xz
            tar xJf materia-dark.tar.xz -C "$THEME_DIR"
            xfconf-query -c xsettings -p /Net/ThemeName -s "Materia-dark"
            xfconf-query -c xfwm4 -p /general/theme -s "Materia-dark"
            ;;
        3)  # macOS
            echo -e "${G}[+] Installing macOS theme...${W}"
            wget -q --show-progress "${THEME_PACKS[3]}" -O macos-theme.tar.gz
            tar xzf macos-theme.tar.gz -C "$THEME_DIR"
            ;;
        5)  # Cyberpunk
            echo -e "${G}[+] Installing Cyberpunk theme...${W}"
            wget -q --show-progress "${THEME_PACKS[5]}" -O cyberpunk-theme.tar.gz
            tar xzf cyberpunk-theme.tar.gz -C "$THEME_DIR"
            git clone https://github.com/sabamdarif/termux-cyberpunk-theme
            cp -r termux-cyberpunk-theme/* ~/.config/
            rm -rf termux-cyberpunk-theme
            ;;
        6)  # WhiteSur Dark
            echo -e "${G}[+] Installing WhiteSur Dark...${W}"
            wget -q --show-progress "${THEME_PACKS[6]}" -O WhiteSur-Dark.tar.xz
            tar xJf WhiteSur-Dark.tar.xz -C "$THEME_DIR"
            xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark"
            xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark"
            ;;
    esac
    rm -f *.tar.*
}

install_app_store() {
    echo -e "${C}[*] Installing Termux App Store...${W}"
    git clone --depth 1 https://github.com/sabamdarif/Termux-AppStore "$APPSTORE_DIR"
    
    cat > "$PREFIX/share/applications/org.termux.appstore.desktop" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Termux App Store
Exec=python $APPSTORE_DIR/src/gtk_app_store.py
Icon=system-software-install
Categories=System;
EOL
    cp "$PREFIX/share/applications/org.termux.appstore.desktop" ~/Desktop/
}

main() {
    clear
    echo -e "${C}┌────────────────────────────┐"
    echo -e "│ Termux XFCE Ultimate By Ejaj Ali │"
    echo -e "└────────────────────────────┘${W}"
    
    # Theme selection
    while true; do
        echo -e "\n${Y}Available Themes:"
        echo -e "  ${B}2${W}) Modern Dark (Materia)"
        echo -e "  ${B}3${W}) macOS Style"
        echo -e "  ${B}5${W}) Cyberpunk"
        echo -e "  ${B}6${W}) WhiteSur Dark (Default)"
        echo -ne "${Y}Enter theme number [2/3/5/6]: ${W}"
        read style_input
        
        [ -z "$style_input" ] && style_input=6
        
        if [[ "$style_input" =~ ^(2|3|5|6)$ ]]; then
            STYLE=$style_input
            break
        else
            echo -e "${R}Invalid selection! Please enter 2, 3, 5, or 6.${W}"
        fi
    done
    
    # System setup
    echo -e "\n${C}[*] Updating system...${W}"
    pkg update -y && pkg upgrade -y
    termux-setup-storage
    echo -e "${C}[*] Installing core packages...${W}"
    pkg install -y x11-repo termux-x11-nightly pulseaudio xfce4 tur-repo \
        firefox code-oss chromium git wget
    
    # DeepEyeCrypto
    echo -e "${C}[*] Installing DeepEyeCrypto...${W}"
    cd ~
    wget -q --show-progress https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/main/DeepEyeCrypto.sh
    chmod +x DeepEyeCrypto.sh
    ./DeepEyeCrypto.sh
    
    # Theme setup
    check_deps
    install_zsh
    install_icons
    setup_wallpapers
    install_theme
    install_app_store
    
    # Completion
    echo -e "\n${C}[√] Installation Complete!${W}"
    echo -e "${Y}Selected Theme:"
    case $STYLE in
        2) echo "Modern Dark (Materia)" ;;
        3) echo "macOS Style" ;;
        5) echo "Cyberpunk" ;;
        6) echo "WhiteSur Dark" ;;
    esac
    echo -e "\n${Y}Commands:"
    echo -e "  themes     - Open appearance settings"
    echo -e "  appstore   - Launch application store"
    echo -e "  iconthemes - List installed icon packs"
    echo -e "  wallpapers - View installed backgrounds"
    echo -e "  zsh        - Restart Zsh shell${W}"
}

main
