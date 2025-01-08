#!/data/data/com.termux/files/usr/bin/bash

# Step 1: Grant Storage Permissions
echo "[+] Granting Termux storage permissions..."
termux-setup-storage
sleep 2

# Step 2: Ensure Script is Executable
echo "[+] Ensuring script has executable permissions..."
chmod +x xfce-macos-setup.sh

# Step 3: Kill open X11 processes
echo "[+] Killing existing X11 processes..."
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Step 4: Enable PulseAudio over Network
echo "[+] Starting PulseAudio server..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Step 5: Prepare Termux-X11 session
echo "[+] Starting Termux-X11 session..."
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait a bit until Termux-X11 gets started
sleep 3

# Step 6: Launch Termux X11 Main Activity
echo "[+] Launching Termux X11 Main Activity..."
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Step 7: Set Audio Server
echo "[+] Setting PulseAudio server environment variable..."
export PULSE_SERVER=127.0.0.1

# Step 8: Install macOS Theme and Icons
echo "[+] Installing macOS theme and icons..."
mkdir -p ~/.themes ~/.icons ~/Pictures/macOS-wallpapers

# Download macOS Theme
wget -O /tmp/Mojave-gtk-theme.zip https://github.com/vinceliuice/Mojave-gtk-theme/archive/refs/heads/master.zip
unzip /tmp/Mojave-gtk-theme.zip -d /tmp/
cd /tmp/Mojave-gtk-theme-master
./install.sh --dest ~/.themes

# Download macOS Icons
wget -O /tmp/McMojave-circle-icons.zip https://github.com/vinceliuice/McMojave-circle/archive/refs/heads/master.zip
unzip /tmp/McMojave-circle-icons.zip -d /tmp/
cd /tmp/McMojave-circle-master
./install.sh --dest ~/.icons

# Step 9: Download macOS Wallpapers
echo "[+] Downloading macOS wallpapers..."
wget -O /tmp/macOS-wallpapers.zip https://github.com/lrusso/macOS-wallpapers/archive/refs/heads/master.zip
unzip /tmp/macOS-wallpapers.zip -d /tmp/
cp -r /tmp/macOS-wallpapers-master/* ~/Pictures/macOS-wallpapers/

# Apply Theme and Icons
echo "[+] Applying macOS theme and icons..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Mojave-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "McMojave-circle"

# Set Wallpaper
echo "[+] Setting macOS wallpaper..."
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s ~/Pictures/macOS-wallpapers/default.jpg

# Configure XFCE4 Panel Layout for macOS-like Dock
echo "[+] Configuring XFCE4 panel layout..."
xfce4-panel-profiles load /tmp/MacOS-like-panel.tar.gz

# Clean up temp files
echo "[+] Cleaning up temporary files..."
rm -rf /tmp/Mojave-gtk-theme* /tmp/McMojave-circle* /tmp/macOS-wallpapers*

# Step 10: Run XFCE4 Desktop
echo "[+] Launching XFCE4 Desktop Environment..."
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session > /dev/null 2>&1 &

# Step 11: Self-Execution if Required
if [[ "$0" != "./xfce-macos-setup.sh" ]]; then
    echo "[+] Re-executing the script to ensure proper initialization..."
    chmod +x xfce-macos-setup.sh
    ./xfce-macos-setup.sh
fi

# Step 12: Finalize
echo "[+] XFCE4 Desktop Environment with macOS theme and wallpapers is starting on Termux X11."

exit 0
