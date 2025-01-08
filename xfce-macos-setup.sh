#!/data/data/com.termux/files/usr/bin/bash

# Step 1: Install Required Packages (if not already installed)
pkg update -y && pkg upgrade -y
pkg install -y x11-repo pulseaudio termux-x11 xfce4 dbus xfce4-session xfce4-terminal xfce4-panel xfce4-whiskermenu-plugin wget unzip git

# Step 2: Kill Existing X11 and PulseAudio Processes
kill -9 $(pgrep -f "termux.x11") 2>/dev/null
kill -9 $(pgrep -f "pulseaudio") 2>/dev/null

# Step 3: Set Permissions for X11 and Temporary Directories
chmod 1777 /tmp
export XDG_RUNTIME_DIR=${TMPDIR}

# Step 4: Start PulseAudio Server
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Step 5: Start Termux-X11 Session
termux-x11 :0 >/dev/null &
sleep 3  # Wait for X11 to initialize

# Step 6: Start Termux X11 Main Activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Step 7: Set Audio Server Environment Variable
export PULSE_SERVER=127.0.0.1

# Step 8: Install macOS Theme and Icons
mkdir -p ~/.themes ~/.icons

# Download macOS Theme
echo "[+] Downloading macOS Theme..."
wget -O /tmp/Mojave-gtk-theme.zip https://github.com/vinceliuice/Mojave-gtk-theme/archive/refs/heads/master.zip
unzip /tmp/Mojave-gtk-theme.zip -d /tmp/
cd /tmp/Mojave-gtk-theme-master
./install.sh --dest ~/.themes

# Download macOS Icons
echo "[+] Downloading macOS Icons..."
wget -O /tmp/McMojave-circle-icons.zip https://github.com/vinceliuice/McMojave-circle/archive/refs/heads/master.zip
unzip /tmp/McMojave-circle-icons.zip -d /tmp/
cd /tmp/McMojave-circle-master
./install.sh --dest ~/.icons

# Set Theme and Icons using XFCE4 Settings
xfconf-query -c xsettings -p /Net/ThemeName -s "Mojave-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "McMojave-circle"

# Configure XFCE4 Panel Layout for macOS-like Dock
xfce4-panel-profiles load /tmp/MacOS-like-panel.tar.gz

# Clean up temp files
rm -rf /tmp/Mojave-gtk-theme* /tmp/McMojave-circle*

# Step 9: Launch XFCE4 Desktop Environment
env DISPLAY=:0 dbus-launch --exit-with-session startxfce4 > /dev/null 2>&1 &

# Step 10: Finalize and Exit
echo "[+] XFCE4 Desktop environment with macOS theme is starting on Termux X11."
echo "[+] Making the script executable and running it again if necessary."

# Make the script executable and run it again if needed
chmod +x xfce4_macos.sh
./xfce4_macos.sh

exit 0
