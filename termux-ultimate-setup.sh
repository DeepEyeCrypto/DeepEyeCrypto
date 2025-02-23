#!/bin/bash

# Termux Desktop Setup Script
set -e # Exit immediately if any command fails

echo "Downloading Termux Desktop setup script..."
curl -Lf https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop -o setup-termux-desktop

echo "Making the script executable..."
chmod +x setup-termux-desktop

echo "Starting installation..."
./setup-termux-desktop

echo "Installation complete!"
