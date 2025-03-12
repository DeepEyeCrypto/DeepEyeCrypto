#!/data/data/com.termux/files/usr/bin/bash

# Termux XFCE WhiteSur Enhanced Theme Script
# Includes: DPI scaling, font installation, and panel configuration

# Enable error handling and logging
set -euo pipefail
exec > >(tee "${HOME}/whitesur-install.log") 2>&1

# Configuration variables
THEME_DIR="${HOME}/.local/share/themes"
ICON_DIR="${HOME}/.local/share/icons"
FONT_DIR="${HOME}/.local/share/fonts"
WALLPAPER_DIR="${HOME}/WhiteSur-Wallpapers"
WORK_DIR="${HOME}/WhiteSur-temp"

# Detect screen density for mobile displays
detect_scaling() {
    local density=96
    if [ -n "$(command -v xdpyinfo)" ]; then
        local res=$(xdpyinfo | grep -oP "dimensions:\s+\K\d+x\d+")
        local width=${res/x*/}
        [ $width -lt 1080 ] && density=120
    fi
    echo $density
}

# Install enhanced dependencies
install_deps() {
    echo "📦 Updating packages and installing dependencies..."
    pkg update -y && pkg install -y \
        git wget curl python libsass \
        xfce4-settings xfce4-panel-profiles \
        x11-repo termux-x11-nightly \
        fontconfig scrot imagemagick
    
    # Install patched fonts
    mkdir -p "${FONT_DIR}"
    wget -qO- https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SanFrancisco/SF-Pro.ttf \
        -O "${FONT_DIR}/SF-Pro.ttf"
    fc-cache -fv
}

# Setup working environment
setup_dirs() {
    echo "📂 Creating directories..."
    mkdir -p "${WORK_DIR}" "${WALLPAPER_DIR}" \
        "${THEME_DIR}" "${ICON_DIR}" "${FONT_DIR}"
    cd "${WORK_DIR}"
}

# Clone and build themes
install_themes() {
    echo "🎨 Installing themes..."
    local repos=(
        "WhiteSur-wallpapers https://github.com/vinceliuice/WhiteSur-wallpapers"
        "WhiteSur-gtk-theme https://github.com/vinceliuice/WhiteSur-gtk-theme"
        "WhiteSur-icon-theme https://github.com/vinceliuice/WhiteSur-icon-theme"
    )

    for repo in "${repos[@]}"; do
        local name=${repo%% *}
        local url=${repo#* }
        echo "🔧 Cloning ${name}..."
        git clone --depth 1 "${url}" || {
            echo "⚠️ Failed to clone ${name}, using fallback..."
            wget -qO- "${url}/archive/main.tar.gz" | tar xz --strip=1
        }
    done

    # GTK Theme with mobile optimizations
    cd WhiteSur-gtk-theme
    ./install.sh -t all -c Dark --tweaks "rimless macos" \
        --dest "${THEME_DIR}" --size standard --transparent

    # Icon Theme with smaller sizes
    cd ../WhiteSur-icon-theme
    ./install.sh -b --black --dest "${ICON_DIR}" --size 32x32

    # Wallpapers
    cd ../WhiteSur-wallpapers
    ./install.sh --dest "${HOME}/.local/share/backgrounds"
}

# Configure XFCE desktop
configure_xfce() {
    echo "🖥  Configuring XFCE4..."
    local density=$(detect_scaling)

    # Apply XFCE settings
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
    xfconf-query -c xsettings -p /Gtk/FontName -s "SF Pro 10"
    xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark"
    xfconf-query -c xfwm4 -p /general/title_font -s "SF Pro Bold 10"
    xfconf-query -c xsettings -p /Xft/DPI -n -t int -s $((density * 1024))

    # Panel configuration (macOS-like layout)
    cat > "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugins" type="array">
        <value type="string" value="applicationsmenu"/>
        <value type="string" value="tasklist"/>
        <value type="string" value="systray"/>
        <value type="string" value="clock"/>
        <value type="string" value="actions"/>
      </property>
    </property>
  </property>
</channel>
EOF

    # Set random wallpaper with imagemagick optimization
    local wall=$(find "${WALLPAPER_DIR}" -type f | shuf -n 1)
    convert "${wall}" -resize 1080x1920^ -gravity center -extent 1080x1920 \
        "${HOME}/.cache/wallpaper-optimized.jpg"
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
        -s "${HOME}/.cache/wallpaper-optimized.jpg"
}

# Post-installation cleanup and checks
finalize() {
    echo "🧹 Cleaning up..."
    rm -rf "${WORK_DIR}"
    
    echo -e "\n✅ Installation Complete! Recommended next steps:"
    echo "1. Restart Termux-X11 session"
    echo "2. Run 'xfce4-panel-profiles' to load custom layouts"
    echo "3. Adjust DPI in ~/.Xresources if needed"
    echo "4. Wallpapers available at: ${WALLPAPER_DIR}"
}

# Main execution flow
install_deps
setup_dirs
install_themes
configure_xfce
finalize
