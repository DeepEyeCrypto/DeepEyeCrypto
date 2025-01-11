#!/data/data/com.termux/files/usr/bin/bash

# Enable Storage Access
termux-setup-storage

# Update and Install Required Packages with Error Handling
pkg update -y || { echo "Failed to update packages."; exit 1; }
pkg upgrade -y || { echo "Failed to upgrade packages."; exit 1; }

# Install Required Packages
packages=(x11-repo termux-x11-nightly pulseaudio wget xfce4 tur-repo firefox proot-distro git unzip plank xfce4-appmenu-plugin chromium htop)
for pkg in "${packages[@]}"; do
    if ! pkg install "$pkg" -y; then
        echo "Failed to install $pkg. Exiting."
        exit 1
    fi
done

# Kill existing Termux X11 processes
pkill -f "termux.x11" 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 || {
    echo "Failed to start PulseAudio."
    exit 1
}

# Prepare Termux X11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null 2>&1 &
sleep 5  # Allow Termux X11 to initialize

# Launch Termux X11 Main Activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || {
    echo "Failed to launch Termux X11."
    exit 1
}

# Export PulseAudio Server Address
export PULSE_SERVER=127.0.0.1

# Start XFCE4 Desktop Environment
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session >/dev/null 2>&1 &

# Install macOS Theme and Icons
mkdir -p ~/.themes ~/.icons
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme
cd ~/WhiteSur-gtk-theme
./install.sh || { echo "Failed to install macOS theme."; exit 1; }

git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme
cd ~/WhiteSur-icon-theme
./install.sh || { echo "Failed to install macOS icons."; exit 1; }

# Set WhiteSur-dark Theme and Icons
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"

# Install macOS Fonts
mkdir -p ~/.fonts
wget https://github.com/supermarin/YosemiteSanFranciscoFont/archive/master.zip -O mac-fonts.zip
unzip mac-fonts.zip -d ~/.fonts || { echo "Failed to unzip macOS fonts."; exit 1; }
fc-cache -fv
xfconf-query -c xsettings -p /Gtk/FontName -s "San Francisco 11"

# macOS Wallpapers
wallpapers=("https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
            "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
            "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
            "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
            "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg")
for wallpaper_url in "${wallpapers[@]}"; do
    wget "$wallpaper_url" -P ~/ || { echo "Failed to download $wallpaper_url."; exit 1; }
done

# Set Default Wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s ~/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg

# Configure Plank Dock
mkdir -p ~/.config/plank/dock1
echo "[DockPreferences]
Position=bottom
IconSize=48
Theme=Transparent" > ~/.config/plank/dock1/settings
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Dock
Comment=Start Plank Dock on XFCE startup" > ~/.config/autostart/plank.desktop
plank &

# Customize XFCE Panel
xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=8;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-0/autohide-behavior -s 2

# Enable XFWM4 Compositing
xfconf-query -c xfwm4 -p /general/use_compositing -s true

# Set macOS-like Window Button Layout
xfconf-query -c xfwm4 -p /general/button_layout -s "close,minimize,maximize:"

# Add macOS-like Keyboard Shortcuts
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>Tab" -s "xfce4-appfinder --collapsed"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>Space" -s "xfce4-appfinder"

# Cleanup Temporary Files
rm -rf ~/WhiteSur-gtk-theme ~/WhiteSur-icon-theme mac-fonts.zip

# Auto-Start on Termux Restart: Add to .bashrc
if ! grep -q "~/DeepEyeCrypto.sh" ~/.bashrc; then
    echo "~/DeepEyeCrypto.sh" >> ~/.bashrc
fi

# Restart XFCE4 for Changes to Apply
xfce4-session-logout --logout
exit 0
