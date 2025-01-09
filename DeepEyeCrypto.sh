#!/data/data/com.termux/files/usr/bin/bash

set -e

# Variables
THEME_REPO="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
ICON_REPO="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
WALLPAPER_URL="https://wallpapercave.com/wp/wp8696495.jpg"
WALLPAPER_PATH="$HOME/.local/share/backgrounds/macos/macos-wallpaper.jpg"
AUTOSTART_DIR="$HOME/.config/autostart"
PLANK_DESKTOP="$AUTOSTART_DIR/plank.desktop"

# Initial Setup and Package Installation
termux-setup-storage

# Update and Install Required Packages
pkg update -y
pkg upgrade -y
pkg install -y x11-repo termux-x11-nightly pulseaudio wget xfce4 tur-repo firefox proot-distro git unzip plank

# Kill existing termux.x11 processes
pkill -f "termux.x11" 2>/dev/null || true

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null 2>&1 &

# Wait for termux-x11 to initialize
for i in {1..10}; do
    if pgrep -f "termux.x11" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Launch Termux X11 Main Activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
sleep 1

# Set PulseAudio server address
export PULSE_SERVER=127.0.0.1

# Start XFCE4 Desktop Environment
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session >/dev/null 2>&1 &

# Install macOS Theme and Icons
mkdir -p ~/.themes ~/.icons

# macOS Theme
if ! git clone $THEME_REPO ~/WhiteSur-gtk-theme; then
    echo "Failed to clone WhiteSur-gtk-theme"
    exit 1
fi
pushd ~/WhiteSur-gtk-theme
./install.sh
popd

# macOS Icons
if ! git clone $ICON_REPO ~/WhiteSur-icon-theme; then
    echo "Failed to clone WhiteSur-icon-theme"
    exit 1
fi
pushd ~/WhiteSur-icon-theme
./install.sh
popd

# macOS Wallpapers
mkdir -p $(dirname $WALLPAPER_PATH)
if ! wget $WALLPAPER_URL -O $WALLPAPER_PATH; then
    echo "Failed to download macos-wallpaper.jpg"
    exit 1
fi

# Apply XFCE4 Theme and Icons (via xfconf)
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"

# Set Wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s $WALLPAPER_PATH

# Configure Plank Dock
mkdir -p $AUTOSTART_DIR
cat <<EOF > $PLANK_DESKTOP
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Dock
Comment=Start Plank Dock on XFCE startup
EOF

# Start Plank immediately
plank &

# Restart XFCE4 for Changes to Apply
xfce4-session-logout --logout

exit 0
