#!/data/data/com.termux/files/usr/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
W="\033[0m"

# Configuration
STYLE=${1:-6}  # Default to WhiteSur Dark
BASE_URL="https://github.com/vinceliuice/WhiteSur-gtk-theme/releases/download/2.0.0/WhiteSur-Dark.tar.xz"
WALLPAPER_DIR="$PREFIX/share/backgrounds"
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"
APPSTORE_DIR="$PREFIX/opt/appstore"
ZSHRC_FILE="$HOME/.zshrc"

# Theme Packages
THEME_PACKS=(
    [3]="https://github.com/sabamdarif/termux-desktop/raw/setup-files/setup-files/xfce/look_3/theme.tar.gz"
    [5]="https://github.com/sabamdarif/termux-desktop/raw/setup-files/setup-files/xfce/look_5/theme.tar.gz"
    [6]="$BASE_URL"
)

# Icon Packs
ICON_PACKS=(
    "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.tar.gz"
    "https://github.com/numixproject/numix-icon-theme/archive/master.tar.gz"
    "https://github.com/keeferrourke/la-capitaine-icon-theme/archive/master.tar.gz"
)

# macOS Wallpapers
MACOS_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
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
        3)  # macOS
            for url in "${MACOS_WALLPAPERS[@]}"; do
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
        3)  # macOS
            wget -q --show-progress "${THEME_PACKS[3]}" 
            tar xzf theme.tar.gz -C "$THEME_DIR"
            ;;
        5)  # Cyberpunk
            wget -q --show-progress "${THEME_PACKS[5]}"
            tar xzf theme.tar.gz -C "$THEME_DIR"
            git clone https://github.com/sabamdarif/termux-cyberpunk-theme
            cp -r termux-cyberpunk-theme/* ~/.config/
            rm -rf termux-cyberpunk-theme
            ;;
        6)  # WhiteSur Dark
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
    echo -e "│ Termux XFCE Ultimate Setup │"
    echo -e "└────────────────────────────┘${W}"
    
    check_deps
    install_zsh
    install_icons
    setup_wallpapers
    install_theme
    install_app_store
    
    echo -e "\n${C}[√] Installation Complete!${W}"
    echo -e "${Y}Restart Termux and use these commands:"
    echo -e " - themes: Open appearance settings"
    echo -e " - appstore: Launch application store"
    echo -e " - iconthemes: List icon packs"
    echo -e " - wallpapers: View installed wallpapers${W}"
}

main
