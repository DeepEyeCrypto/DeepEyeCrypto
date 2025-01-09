#!/bin/bash

# Update and upgrade Termux packages
echo "[*] Updating Termux packages..."
pkg update -y && pkg upgrade -y

# Install necessary dependencies
echo "[*] Installing dependencies..."
pkg install -y wget git proot openssh x11-repo xfce4 aterm xterm

# Download the Kali NetHunter installer
echo "[*] Downloading Kali NetHunter installer..."
wget -O install-nethunter-termux https://offs.ec/2MceZWr
chmod +x install-nethunter-termux

# Install Kali NetHunter
echo "[*] Installing Kali NetHunter..."
./install-nethunter-termux

# Configure X11 forwarding
echo "[*] Setting up X11 forwarding..."
echo "export DISPLAY=:0" >> ~/.bashrc
source ~/.bashrc

# Ensure X server is running on host
echo "[*] To use X11 apps, ensure your X server is running (e.g., XServer XSDL for Android)."
echo "[*] Once running, launch GUI apps in NetHunter as follows:"
echo "   nethunter"
echo "   export DISPLAY=:0"
echo "   xterm (or any other GUI app)"
echo "[*] Setup complete!"
