#!/data/data/com.termux/files/usr/bin/bash

# Set up storage access
termux-setup-storage

# Update packages and install necessary dependencies
pkg update -y
pkg install x11-repo -y
pkg install termux-x11-nightly -y
pkg install pulseaudio -y
pkg install wget -y
pkg install xfce4 -y
pkg install tur-repo -y
pkg install firefox -y
pkg install git -y

# Kill open X11 processes
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait a bit until termux-x11 gets started.
sleep 3

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Set audio server
export PULSE_SERVER=127.0.0.1

# Run XFCE4 Desktop
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

# Clone macOS GTK theme
git clone https://github.com/vinceliuice/macOS.git

# Install macOS theme
cd macOS
./install.sh

# Apply macOS GTK theme globally
xfconf-query --channel xsettings --property /Net/ThemeName --set "macOS"

# Set icons and cursor for macOS look (optional)
xfconf-query --channel xsettings --property /Net/IconThemeName --set "macOS"
xfconf-query --channel xsettings --property /Gtk/CursorThemeName --set "macOS"

# Launch the macOS dock (optional)
plank &

# Exit script
exit 0
