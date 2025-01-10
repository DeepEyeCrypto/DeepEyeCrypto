#!/data/data/com.termux/files/usr/bin/bash

# Initial Setup and Package Installation
termux-setup-storage

# Update and Install Required Packages
pkg update -y
pkg upgrade -y
pkg install x11-repo -y
pkg install termux-x11-nightly -y
pkg install pulseaudio -y
pkg install wget -y
pkg install xfce4 -y
pkg install tur-repo -y
pkg install firefox -y
pkg install proot-distro -y
pkg install git -y
pkg install unzip -y
pkg install plank -y

# Kill existing termux.x11 processes
pkill -f "termux.x11" 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start \
    --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
    --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null 2>&1 &

# Wait for termux-x11 to initialize
sleep 3

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
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme
cd ~/WhiteSur-gtk-theme
./install.sh

# macOS Icons
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme
cd ~/WhiteSur-icon-theme
./install.sh

# macOS Wallpapers
mkdir -p ~/Home
cd ~/Home
wget https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg
wget https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg
wget https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg
wget https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg
wget https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg

# Apply XFCE4 Theme and Icons (via xfconf)
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"

# Set Wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s ~/Home/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg

# Configure Plank Dock
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Dock
Comment=Start Plank Dock on XFCE startup" > ~/.config/autostart/plank.desktop

# Start Plank immediately
plank &

# Restart XFCE4 for Changes to Apply
xfce4-session-logout --logout

exit 0
