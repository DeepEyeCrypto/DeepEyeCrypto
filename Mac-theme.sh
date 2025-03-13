#!/data/data/com.termux/files/usr/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
B="\033[1;34m"
C="\033[1;36m"
W="\033[0m"

# Configuration
THEME_DIR="$HOME/.themes"
ICON_DIR="$HOME/.icons"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
FONT_DIR="$HOME/.fonts"

# Theme Options
declare -A THEMES=(
    [1]="WhiteSur-Dark"
    [2]="McMojave"
    [3]="Cupertino"
    [4]="Monterey"
    [5]="Ventura"
)

# Resources
declare -A THEME_REPO=(
    ["WhiteSur"]="https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/master.tar.gz"
    ["McMojave"]="https://github.com/paullinuxthemer/McMojave-theme/archive/master.zip"
    ["Cupertino"]="https://github.com/alexaylwin/Cupertino-gtk-theme/archive/refs/heads/master.zip"
    ["Monterey"]="https://github.com/vinceliuice/Monterey-kde/archive/master.tar.gz"
    ["Ventura"]="https://github.com/3ximus/macos-ventura-theme/archive/refs/heads/main.zip"
)

declare -A ICON_REPO=(
    ["WhiteSur"]="https://github.com/vinceliuice/WhiteSur-icon-theme/archive/master.tar.gz"
    ["McMojave"]="https://github.com/zayronxio/McMojave-circle/archive/master.zip"
    ["Cupertino"]="https://github.com/alexaylwin/Cupertino-mocha-icons/archive/refs/heads/master.zip"
)

declare -A WALLPAPER_REPO=(
    "https://4kwallpapers.com/images/wallpapers/macos-monterey-abstract-wwdc-2021-5k-7680x4320-2353.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-ventura-abstract-stock-dark-mode-5k-7680x4320-7001.jpeg"
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
)

show_menu() {
    clear
    echo -e "${C}┌───────────────────────────────────┐"
    echo -e "│ Termux macOS Theme Suite v2.1    │"
    echo -e "└───────────────────────────────────┘${W}"
    echo -e "${B}Select macOS Theme:${W}"
    for key in "${!THEMES[@]}"; do
        echo -e "${Y} $key) ${THEMES[$key]}${W}"
    done
    echo -e "${Y} 6) Install All Components${W}"
    echo -e "${R} 0) Exit${W}"
}


install_fonts() {
    echo -e "${C}[*] Installing macOS fonts...${W}"
    mkdir -p "$FONT_DIR"
    wget -q --show-progress "https://github.com/samuelngs/apple-emoji-linux/archive/refs/heads/master.zip" -O "apple-fonts.zip"
    unzip -q apple-fonts.zip -d "$FONT_DIR"
    rm apple-fonts.zip
    fc-cache -f -v
}

install_theme() {
    local theme="$1"
    echo -e "${G}[+] Installing ${THEMES[$theme]}...${W}"
    
    case $theme in
        1) # WhiteSur
            install_whitesur
            ;;
        2) # McMojave
            wget -q --show-progress "${THEME_REPO[McMojave]}" -O "mcmojave.zip"
            unzip -q mcmojave.zip -d "$THEME_DIR"
            mv "$THEME_DIR/McMojave-theme-master/McMojave" "$THEME_DIR/McMojave"
            rm -rf "$THEME_DIR/McMojave-theme-master" mcmojave.zip
            ;;
        3) # Cupertino
            wget -q --show-progress "${THEME_REPO[Cupertino]}" -O "cupertino.zip"
            unzip -q cupertino.zip -d "$THEME_DIR"
            mv "$THEME_DIR/Cupertino-gtk-theme-master" "$THEME_DIR/Cupertino"
            rm cupertino.zip
            ;;
        4) # Monterey
            wget -q --show-progress "${THEME_REPO[Monterey]}" -O "monterey.tar.gz"
            tar xzf monterey.tar.gz -C "$THEME_DIR"
            mv "$THEME_DIR/Monterey-kde-master" "$THEME_DIR/Monterey"
            rm monterey.tar.gz
            ;;
        5) # Ventura
            wget -q --show-progress "${THEME_REPO[Ventura]}" -O "ventura.zip"
            unzip -q ventura.zip -d "$THEME_DIR"
            mv "$THEME_DIR/macos-ventura-theme-main" "$THEME_DIR/Ventura"
            rm ventura.zip
            ;;
    esac
}

install_whitesur() {
    wget -q --show-progress "${THEME_REPO[WhiteSur]}" -O "whitesur.tar.gz"
    tar xzf whitesur.tar.gz
    mv WhiteSur-gtk-theme-master/themes/WhiteSur-Dark "$THEME_DIR"
    mv WhiteSur-gtk-theme-master/themes/WhiteSur-Dark-solid "$THEME_DIR"
    rm -rf WhiteSur-gtk-theme-master whitesur.tar.gz
}

install_icons() {
    local icon_theme="$1"
    echo -e "${G}[+] Installing ${icon_theme} icons...${W}"
    
    case $icon_theme in
        "WhiteSur")
            wget -q --show-progress "${ICON_REPO[WhiteSur]}" -O "whitesur-icons.tar.gz"
            tar xzf whitesur-icons.tar.gz -C "$ICON_DIR"
            mv "$ICON_DIR/WhiteSur-icon-theme-master" "$ICON_DIR/WhiteSur"
            rm whitesur-icons.tar.gz
            ;;
        "McMojave")
            wget -q --show-progress "${ICON_REPO[McMojave]}" -O "mcmojave-icons.zip"
            unzip -q mcmojave-icons.zip -d "$ICON_DIR"
            mv "$ICON_DIR/McMojave-circle-master" "$ICON_DIR/McMojave"
            rm mcmojave-icons.zip
            ;;
        "Cupertino")
            wget -q --show-progress "${ICON_REPO[Cupertino]}" -O "cupertino-icons.zip"
            unzip -q cupertino-icons.zip -d "$ICON_DIR"
            mv "$ICON_DIR/Cupertino-mocha-icons-master" "$ICON_DIR/Cupertino"
            rm cupertino-icons.zip
            ;;
    esac
    
    gtk-update-icon-cache -f -t "$ICON_DIR/$icon_theme"
}

setup_wallpapers() {
    echo -e "${C}[*] Configuring macOS wallpapers...${W}"
    mkdir -p "$WALLPAPER_DIR"
    
    for wall in "${MAC_WALLPAPERS[@]}"; do
        filename=$(basename "$wall")
        echo -e "${G}[+] Downloading $filename...${W}"
        wget -q --show-progress "$wall" -P "$WALLPAPER_DIR"
        
        if [[ "$filename" == *".jpeg" ]]; then
            convert "$WALLPAPER_DIR/$filename" "${WALLPAPER_DIR}/${filename%.*}.png"
            rm "$WALLPAPER_DIR/$filename"
        fi
    done
}

configure_xfce() {
    local theme="$1"
    echo -e "${C}[*] Applying ${THEMES[$theme]} configuration...${W}"
    
    xfconf-query -c xsettings -p /Net/ThemeName -s "${THEMES[$theme]}"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
    xfconf-query -c xfwm4 -p /general/theme -s "${THEMES[$theme]}"
    
    if [ -f "$THEME_DIR/${THEMES[$theme]}/xfce-notify-4.0/gtk.css" ]; then
        cp "$THEME_DIR/${THEMES[$theme]}/xfce-notify-4.0/gtk.css" "$HOME/.config/gtk-4.0/"
    fi
}

final_config() {
    echo -e "${C}[*] Finalizing setup...${W}"
    termux-x11 :0 &
    sleep 2
    pulseaudio --start
    dbus-launch --exit-with-session xfce4-session &
}

main() {
    initial_setup
    install_deps
    install_fonts
    
    while true; do
        show_menu
        read -p "Select option (0-6): " choice
        
        case $choice in
            1|2|3|4|5)
                install_theme $choice
                install_icons "WhiteSur"
                setup_wallpapers
                configure_xfce $choice
                final_config
                ;;
            6)
                for theme in "${!THEMES[@]}"; do
                    [ $theme -eq 0 ] && continue
                    install_theme $theme
                done
                for icon in "${!ICON_REPO[@]}"; do
                    install_icons "$icon"
                done
                setup_wallpapers
                configure_xfce 1  # Default to WhiteSur
                final_config
                ;;
            0)
                echo -e "${R}Exiting...${W}"
                exit 0
                ;;
            *)
                echo -e "${R}Invalid option!${W}"
                ;;
        esac
        
        echo -e "\n${C}[√] ${THEMES[$choice]} installation complete!"
        echo -e "${Y}Restart XFCE session to see changes"
        echo -e "Run: xfce4-session${W}\n"
        read -p "Press enter to continue..."
    done
}

main
