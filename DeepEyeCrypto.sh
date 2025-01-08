#!/data/data/com.termux/files/usr/bin/bash

# Kill open X11 processes
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait until termux-x11 starts
sleep 3

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Set audio server
export PULSE_SERVER=127.0.0.1

# Install Required Packages
pkg update && pkg upgrade -y
pkg install git wget gtk2 gtk3 xfce4-settings plank -y

# Download and Install macOS Theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh
cd ..

# Download and Install macOS Icon Theme
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh
cd ..

# Download macOS Wallpapers
git clone https://github.com/joeyhoer/macOS-Wallpapers.git
mkdir -p ~/.wallpapers
cp macOS-Wallpapers/* ~/.wallpapers/

# Set XFCE4 Appearance and Icons
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"

# Set macOS Wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "~/.wallpapers/macos-default.jpg"

# Enable macOS Dock
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Start Plank dock" > ~/.config/autostart/plank.desktop

plank &

# Run XFCE4 Desktop
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

exit 0
