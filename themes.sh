#!/data/data/com.termux/files/usr/bin/bash

# Define common paths
THEME_DIR="/data/data/com.termux/files/home/.themes"
ICON_DIR="/data/data/com.termux/files/home/.icons"
CURSOR_DIR="/data/data/com.termux/files/home/.icons/cursors"
WHITE_SUR_THEME_REPO="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
WHITE_SUR_ICON_REPO="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
ARC_THEME_REPO="https://github.com/horst3180/arc-theme"
NUMIX_THEME_REPO="https://github.com/numixproject/numix-gtk-theme"
ADAPTA_THEME_REPO="https://github.com/adapta-project/adapta-gtk-theme"
CAPITAINE_CURSOR_REPO="https://github.com/keeferrourke/capitaine-cursors.git"

# Initial Setup and Package Installation
function setup_environment() {
    termux-setup-storage
    pkg update -y && pkg upgrade -y
    pkg install -y wget git unzip xfce4-appmenu-plugin ruby zsh htop tmux ncdu neofetch ranger curl wget ffmpeg irssi mutt exa bat ripgrep fzf httpie tldr procs glances fd neovim || exit 1
}

# Install macOS Theme and Icons
function install_macos_themes_and_icons() {
    mkdir -p "$THEME_DIR" "$ICON_DIR"

    # macOS Theme
    git clone "$WHITE_SUR_THEME_REPO" "$THEME_DIR/WhiteSur-gtk-theme" || exit 1
    cd "$THEME_DIR/WhiteSur-gtk-theme" || exit 1
    ./install.sh || exit 1

    # Extract macOS Themes
    cd "$THEME_DIR" || exit 1
    for theme in WhiteSur-Dark WhiteSur-Dark-nord WhiteSur-Dark-solid WhiteSur-Dark-solid-nord WhiteSur-Light WhiteSur-Light-nord WhiteSur-Light-solid WhiteSur-Light-solid-nord; do
        tar -xf "$THEME_DIR/WhiteSur-gtk-theme/release/$theme.tar.xz" || exit 1
        rm "$THEME_DIR/WhiteSur-gtk-theme/release/$theme.tar.xz"  # Delete the tar file after extraction
    done

    # macOS Icons
    git clone "$WHITE_SUR_ICON_REPO" ~/WhiteSur-icon-theme || exit 1
    cd ~/WhiteSur-icon-theme || exit 1
    ./install.sh || exit 1

    # candy-icons
    wget https://github.com/EliverLara/candy-icons/archive/refs/heads/master.zip -O ~/candy-icons.zip || exit 1
    mkdir -p "$ICON_DIR"
    unzip ~/candy-icons.zip -d "$ICON_DIR" || exit 1
    rm ~/candy-icons.zip  # Delete the zip file after extraction

    # Set WhiteSur-dark Theme and Icons
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark" || exit 1
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark" || exit 1
}

# Install Additional Themes
function install_additional_themes() {
    mkdir -p "$THEME_DIR" "$ICON_DIR"

    # Arc Theme
    git clone "$ARC_THEME_REPO" "$THEME_DIR/arc-theme" || exit 1
    cd "$THEME_DIR/arc-theme" || exit 1
    ./autogen.sh --prefix=$PREFIX || exit 1
    make install || exit 1

    # Numix Theme
    git clone "$NUMIX_THEME_REPO" "$THEME_DIR/numix-gtk-theme" || exit 1
    cd "$THEME_DIR/numix-gtk-theme" || exit 1
    ./autogen.sh --prefix=$PREFIX || exit 1
    make install || exit 1

    # Adapta Theme
    git clone "$ADAPTA_THEME_REPO" "$THEME_DIR/adapta-gtk-theme" || exit 1
    cd "$THEME_DIR/adapta-gtk-theme" || exit 1
    ./autogen.sh --prefix=$PREFIX || exit 1
    make install || exit 1
}

# Install Capitaine Cursor Theme
function install_capitaine_cursors() {
    mkdir -p "$CURSOR_DIR"

    # Capitaine Cursors
    git clone "$CAPITAINE_CURSOR_REPO" "$CURSOR_DIR/capitaine-cursors" || exit 1
    cd "$CURSOR_DIR/capitaine-cursors" || exit 1
    ./install.sh || exit 1

    # Set Capitaine Cursor Theme
    xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "capitaine-cursors" || exit 1
}

# Set macOS Wallpapers
function set_wallpapers() {
    cd /data/data/com.termux/files/home || exit 1
    wget https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg -O big-sur.jpg || exit 1
    wget https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg -O fusion.jpg || exit 1
    wget https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg -O sonoma1.jpg || exit 1
    wget https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg -O sonoma2.jpg || exit 1
    wget https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg -O high-sierra.jpg || exit 1

    # Set Default Wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s /data/data/com.termux/files/home/big-sur.jpg || exit 1
}

# Optional: Add Wallpaper Rotation
function rotate_wallpapers() {
    while true; do
        for wallpaper in /data/data/com.termux/files/home/*.jpg; do
            xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$wallpaper" || exit 1
            sleep 3600  # Change every hour
        done
    done &
}

# Terminal Utility Setup Function
function terminal_utility_setup() {
    # Checking if terminal utility setup should be skipped
    if [[ "$terminal_utility_setup_answer" == "n" ]]; then
        return
    fi

    # Installing terminal utilities
    pkg install -y bat eza zoxide fastfetch openssh fzf zsh || exit 1

    # Backup and modify Termux configuration files
    cp $PREFIX/etc/motd $PREFIX/etc/motd.bak || exit 1
    echo "Custom Configuration" > $PREFIX/etc/motd

    # Add custom functions and aliases to shell configuration file
    {
        echo 'alias ll="eza -al --color=always --group-directories-first"'
        echo 'eval "$(zoxide init bash)"'
    } >> ~/.bashrc

    # Source the updated shell configuration
    source ~/.bashrc || exit 1
}

# Main Execution
setup_environment
install_macos_themes_and_icons
install_additional_themes
install_capitaine_cursors
set_wallpapers
rotate_wallpapers
terminal_utility_setup

exit 0
