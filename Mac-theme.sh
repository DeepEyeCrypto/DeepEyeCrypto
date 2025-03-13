#!/data/data/com.termux/files/usr/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
W="\033[0m"

# Configuration
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"

initial_setup() {
    echo -e "${C}[*] Starting initial setup...${W}"
    
    # Update packages
    echo -e "${G}[+] Updating packages...${W}"
    pkg update -y && pkg upgrade -y
    
    # Setup storage
    echo -e "${G}[+] Setting up storage...${W}"
    termux-setup-storage
    sleep 2  # Allow time for permission grant
    
    # Install core components
    echo -e "${G}[+] Installing base system...${W}"
    pkg install -y x11-repo termux-x11-nightly pulseaudio \
        xfce4 tur-repo firefox chromium code-oss git wget
    
    # Install theme dependencies
    echo -e "${G}[+] Installing theme requirements...${W}"
    pkg install -y meson ninja imagemagick lxappearance
    
    # Create essential directories
    mkdir -p {$ICON_DIR,$THEME_DIR,$WALLPAPER_DIR}
}

install_macos_theme() {
    echo -e "${C}[*] Installing macOS Monterey Theme...${W}"
    
    # GTK Theme
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -d $THEME_DIR -c dark -t mojave
    cd .. && rm -rf WhiteSur-gtk-theme
    
    # Icons
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh -d $ICON_DIR
    cd .. && rm -rf WhiteSur-icon-theme
    
    # Cursors
    git clone https://github.com/vinceliuice/WhiteSur-cursors.git
    cd WhiteSur-cursors
    ./install.sh -d $ICON_DIR
    cd .. && rm -rf WhiteSur-cursors
    
    # Wallpapers
    wget -q --show-progress https://github.com/termux/xfce-packages/raw/master/backgrounds/xfce/macos-monterey.jpg
    mv macos-monterey.jpg $WALLPAPER_DIR
    
    echo -e "${G}[+] macOS theme components installed!${W}"
}

configure_system() {
    echo -e "${C}[*] Configuring desktop environment...${W}"
    
    # Set theme
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
    xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-dark"
    
    # Set wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER_DIR/macos-monterey.jpg"
    
    # Create autostart
    mkdir -p ~/.config/autostart
    echo -e "[Desktop Entry]\nType=Application\nExec=termux-x11\nX-GNOME-Autostart-enabled=true" > ~/.config/autostart/termux-x11.desktop
}

final_steps() {
    echo -e "${C}[*] Finalizing installation...${W}"
    
    # Install DeepEyeCrypto
    cd ~
    wget -q --show-progress https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh
    chmod +x DeepEyeCrypto.sh
    
    echo -e "${Y}[!] Warning: About to execute external script${W}"
    bash DeepEyeCrypto.sh
}

main() {
    clear
    echo -e "${C}┌──────────────────────────────────────────┐"
    echo -e "│ Termux XFCE + macOS Complete Setup by Ejaj Ali"
    echo -e "└──────────────────────────────────────────┘${W}"
    
    initial_setup
    install_macos_theme
    configure_system
    final_steps
    
    echo -e "\n${C}[√] Installation Complete!"
    echo -e "${Y}Components installed:"
    echo -e " - XFCE Desktop Environment"
    echo -e " - macOS Monterey Theme & Icons"
    echo -e " - Development Tools (code-oss, git)"
    echo -e " - Browsers (Firefox, Chromium)"
    echo -e " - DeepEyeCrypto System"
    echo -e "\n${R}Restart Termux session to apply all changes!${W}"
}

main
