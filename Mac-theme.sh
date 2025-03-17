#!/bin/bash

# Update and upgrade packages
pkg update -y && pkg upgrade -y

# Setup storage permissions
termux-setup-storage

# Install X11 components
pkg install x11-repo -y
pkg install termux-x11-nightly -y

# Install audio server
pkg install pulseaudio -y

# Install desktop environment
pkg install xfce4 -y

# Add third-party repo (only need to install once)
pkg install tur-repo -y

# Install applications
pkg install firefox code-oss chromium git wget -y

# Download and execute DeepEyeCrypto script
cd ~
wget https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/DeepEyeCrypto.sh
chmod +x DeepEyeCrypto.sh
bash DeepEyeCrypto.sh

echo "Installation complete!"
