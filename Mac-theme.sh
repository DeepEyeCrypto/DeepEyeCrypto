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
TEMP_DIR="$HOME/.temp_theme_setup"

# Theme Resources
declare -A THEME_REPO=(
    ["WhiteSur"]="https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/master.tar.gz"
    ["McMojave"]="https://github.com/paullinuxthemer/McMojave-theme/archive/refs/heads/master.zip"
    ["Monterey"]="https://github.com/vinceliuice/Monterey-kde/archive/refs/heads/master.tar.gz"
)

declare -A ICON_REPO=(
    ["WhiteSur"]="https://github.com/vinceliuice/WhiteSur-icon-theme/archive/master.tar.gz"
    ["McMojave"]="https://github.com/zayronxio/McMojave-circle/archive/refs/heads/master.zip"
)

MAC_WALLPAPERS=(
    "https://4kwallpapers.com/images/wallpapers/macos-monterey-abstract-wwdc-2021-5k-7680x4320-2353.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
)

handle_error() {
    echo -e "${R}[!] Error occurred at line $1${W}"
    echo -e "${R}[!] Cleaning up...${W}"
    rm -rf "$TEMP_DIR"
    exit 1
}

trap 'handle_error $LINENO' ERR

initial_setup() {
    echo -e "${C}[*] Initializing system setup...${W}"
    
    # Update packages
    pkg update -y && pkg upgrade -y
    
    # Setup storage
    termux-setup-storage
    echo -e "${Y}[!] Grant storage permissions when prompted!${W}"
    sleep 2

    # Install core components
    pkg install -y x11-repo termux-x11-nightly pulseaudio \
        xfce4 tur-repo firefox chromium code-oss git wget \
        unzip meson ninja imagemagick lxappendance sassc \
        libxml2 glib binutils

    # Create directories
    mkdir -p {"$THEME_DIR","$ICON_DIR","$WALLPAPER_DIR","$FONT_DIR","$TEMP_DIR"}
}

install_fonts() {
    echo -e "${C}[*] Installing macOS fonts...${W}"
    wget -q --show-progress "https://github.com/samuelngs/apple-emoji-linux/archive/refs/heads/master.zip" -O "$TEMP_DIR/apple-fonts.zip"
    unzip -q "$TEMP_DIR/apple-fonts.zip" -d "$FONT_DIR"
    fc-cache -f -v
}

install_component() {
    local url="$1"
    local target_dir="$2"
    local name="$3"
    
    echo -e "${G}[+] Installing $name...${W}"
    
    local ext="${url##*.}"
    local temp_file="$TEMP_DIR/$name.$ext"
    
    wget -q --show-progress "$url" -O "$temp_file"
    
    case $ext in
        "zip") unzip -q "$temp_file" -d "$TEMP_DIR" ;;
        "gz") tar -xzf "$temp_file" -C "$TEMP_DIR" ;;
    esac

    # Handle extracted content
    find "$TEMP_DIR" -maxdepth 1 -type d -name "*$name*" -exec mv {} "$target_dir/$name" \;
    
    # Special post-install actions
    case $name in
        "WhiteSur")
            (cd "$target_dir/$name" && ./install.sh -d "$THEME_DIR" -c dark -t mojave)
            ;;
        "McMojave")
            mv "$target_dir/$name/McMojave-theme-master/McMojave" "$target_dir/$name"
            ;;
    esac
}

setup_themes() {
    echo -e "${C}[*] Installing macOS themes...${W}"
    for theme in "${!THEME_REPO[@]}"; do
        install_component "${THEME_REPO[$theme]}" "$THEME_DIR" "$theme"
    done
}

setup_icons() {
    echo -e "${C}[*] Installing icon sets...${W}"
    for icon in "${!ICON_REPO[@]}"; do
        install_component "${ICON_REPO[$icon]}" "$ICON_DIR" "$icon"
        gtk-update-icon-cache -f -t "$ICON_DIR/$icon"
    done
}

setup_wallpapers() {
    echo -e "${C}[*] Configuring wallpapers...${W}"
    for wall in "${MAC_WALLPAPERS[@]}"; do
        local filename=$(basename "$wall")
        wget -q --show-progress "$wall" -P "$WALLPAPER_DIR"
        
        # Convert to PNG if needed
        if [[ "$filename" == *".jpeg" || "$filename" == *".jpg" ]]; then
            convert "$WALLPAPER_DIR/$filename" "${WALLPAPER_DIR}/${filename%.*}.png"
            rm -f "$WALLPAPER_DIR/$filename"
        fi
    done
}

configure_xfce() {
    echo -e "${C}[*] Applying macOS configuration...${W}"
    
    # Theme settings
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark" || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur" || true
    xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-dark" || true
    
    # Wallpaper settings
    local first_wall=$(ls "$WALLPAPER_DIR" | head -1)
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER_DIR/$first_wall" || true
    
    # Panel configuration
    mkdir -p ~/.config/xfce4/panel
    echo -e "[config]\narrangement=0" > ~/.config/xfce4/panel/default.xml
}

setup_deepeye() {
    echo -e "${C}[*] Installing DeepEyeCrypto...${W}"
    cd ~
    wget -q --show-progress "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh"
    chmod +x DeepEyeCrypto.sh
    bash DeepEyeCrypto.sh
}

cleanup() {
    echo -e "${C}[*] Cleaning temporary files...${W}"
    rm -rf "$TEMP_DIR"
}

main() {
    clear
    echo -e "${C}┌─────────────────────────────────────────────┐"
    echo -e "│ Termux macOS Desktop Environment Installer │"
    echo -e "└─────────────────────────────────────────────┘${W}"
    
    initial_setup
    install_fonts
    setup_themes
    setup_icons
    setup_wallpapers
    configure_xfce
    setup_deepeye
    cleanup

    echo -e "\n${C}[√] Installation Complete!"
    echo -e "${Y}To start the desktop environment:"
    echo -e "1. termux-x11 :0 &"
    echo -e "2. pulseaudio --start"
    echo -e "3. dbus-launch xfce4-session"
    echo -e "\n${R}Note: First launch may take 1-2 minutes!${W}"
}

main
