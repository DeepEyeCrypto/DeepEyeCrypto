#!/data/data/com.termux/files/usr/bin/bash

# Step 1: Grant Storage Permissions
echo "[+] Granting Termux storage permissions..."
termux-setup-storage
sleep 2

# Step 2: Install Required Packages (if not already installed)
echo "[+] Installing required packages..."
pkg update -y && pkg upgrade -y
pkg install -y x11-repo pulseaudio termux-x11 xfce4 dbus xfce4-session xfce4-terminal xfce4-panel xfce4-whiskermenu-plugin wget unzip git

# Step 3: Kill Existing X11 and PulseAudio Processes
echo "[+] Killing existing X11 and PulseAudio processes..."
kill -9 $(pgrep -f "termux.x11") 2>/dev/null
kill -9 $(pgrep -f "pulseaudio") 2>/dev/null

# Step 4: Set Permissions for X11 and Temporary Directories
echo "[+] Setting permissions for X11 and temporary directories..."
chmod 1777 /tmp
export XDG_RUNTIME_DIR=${TMPDIR}

# Step 5: Start PulseAudio Server
echo "[+] Starting PulseAudio server..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Step 6: Start Termux-X11 Session
echo "[+] Starting Termux-X11 session..."
termux-x11 :0 >/dev/null &
sleep 3  # Wait for X11 to initialize

# Step 7: Start Termux X11 Main Activity
echo "[+] Starting Termux X11 main activity..."
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Step 8: Set Audio Server Environment Variable
echo "[+] Setting PulseAudio server environment variable..."
export PULSE_SERVER=127.0.0.1

# Step 9: Install macOS Theme and Icons
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
echo "[+] Applying macOS theme and icons..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Mojave-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "McMojave-circle"

# Configure XFCE4 Panel Layout for macOS-like Dock
echo "[+] Configuring XFCE4 panel layout..."
xfce4-panel-profiles load /tmp/MacOS-like-panel.tar.gz

# Clean up temp files
echo "[+] Cleaning up temporary files..."
rm -rf /tmp/Mojave-gtk-theme* /tmp/McMojave-circle*

# Step 10: Launch XFCE4 Desktop Environment
echo "[+] Launching XFCE4 Desktop Environment..."
env DISPLAY=:0 dbus-launch --exit-with-session startxfce4 > /dev/null 2>&1 &

# Step 11: Finalize and Exit
echo "[+] XFCE4 Desktop environment with macOS theme is starting on Termux X11."
echo "[+] Making the script executable and running it again if necessary."

# Make the script executable and run it again if needed
chmod +x xfce4_macos.sh
./xfce4_macos.sh

exit 0
