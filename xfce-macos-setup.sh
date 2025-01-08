#!/data/data/com.termux/files/usr/bin/bash

# Initial Setup and Package Installation
termux-setup-storage

# Update and Install Required Packages
pkg update -y
pkg install x11-repo -y
pkg install termux-x11-nightly -y
pkg install pulseaudio -y
pkg install wget -y
pkg install xfce4 -y
pkg install tur-repo -y
pkg install firefox -y
pkg install proot-distro -y
pkg install git -y

# Run XFCE macOS Setup Script
if [[ -f "./xfce-macos-setup.sh" ]]; then
    chmod +x ./xfce-macos-setup.sh
    ./xfce-macos-setup.sh
else
    echo "Error: ./xfce-macos-setup.sh not found. Skipping setup script."
fi

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

exit 0
