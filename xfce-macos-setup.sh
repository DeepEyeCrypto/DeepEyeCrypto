#!/bin/bash

# -------------------------------
# One-Click XFCE macOS Themed Setup for Termux
# -------------------------------

# Step 1: Storage Permissions
echo "[+] Setting up Termux storage access..."
termux-setup-storage

# Step 2: Update and Upgrade Packages
echo "[+] Updating and upgrading packages..."
pkg update -y && pkg upgrade -y

# Step 3: Install Required Repositories and Packages
echo "[+] Installing necessary repositories and packages..."
pkg install x11-repo -y
pkg install termux-x11-nightly pulseaudio xfce4 firefox git gtk3 xfconf plank -y

# Step 4: Start X11 Server
echo "[+] Starting X11 server..."
termux-x11 :1 &

# Wait for X11 to Initialize
sleep 2

# Set DISPLAY Variable
export DISPLAY=:1

# Start PulseAudio for Sound
echo "[+] Starting PulseAudio..."
pulseaudio --start

# Step 5: Install macOS Theme and Icons
echo "[+] Installing macOS theme and icons..."

# Create necessary directories
mkdir -p ~/.themes ~/.icons

# Install WhiteSur GTK Theme
if [ ! -d "~/WhiteSur-gtk-theme" ]; then
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme
    cd ~/WhiteSur-gtk-theme
    ./install.sh
    cd ~
else
    echo "[+] WhiteSur GTK Theme already installed."
fi

# Install WhiteSur Icon Theme
if [ ! -d "~/WhiteSur-icon-theme" ]; then
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme
    cd ~/WhiteSur-icon-theme
    ./install.sh
    cd ~
else
    echo "[+] WhiteSur Icon Theme already installed."
fi

# Apply Themes
echo "[+] Applying macOS theme and icons..."
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"

# Step 6: Set Up Plank Dock
echo "[+] Configuring Plank dock..."
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Plank Dock" > ~/.config/autostart/plank.desktop

# Step 7: Add XFCE Alias to .bashrc
echo "[+] Adding XFCE alias to .bashrc..."
if ! grep -q 'alias xfce="~/xfce-macos-setup.sh"' ~/.bashrc; then
    echo 'alias xfce="~/xfce-macos-setup.sh"' >> ~/.bashrc
    source ~/.bashrc
    echo "[+] Alias added successfully!"
else
    echo "[+] Alias already exists in .bashrc"
fi

# Step 8: Launch XFCE Desktop
echo "[+] Launching XFCE Desktop..."
startxfce4 &

# Step 9: Launch Plank Dock
echo "[+] Starting Plank dock..."
plank &
