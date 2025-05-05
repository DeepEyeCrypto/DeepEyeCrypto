#!/bin/bash

# Script to install selected Xfce4 panel plugins on Debian-based systems

# List of plugins to install
PLUGINS=(
    xfce4-whiskermenu-plugin
    xfce4-pulseaudio-plugin
    xfce4-clipman-plugin
    xfce4-cpugraph-plugin
    xfce4-systemload-plugin
    xfce4-weather-plugin
    xfce4-genmon-plugin
    xfce4-docklike-plugin
    xfce4-xkb-plugin
    xfce4-notes-plugin
)

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Update package index
echo "Updating package index..."
apt-get update -y
if [ $? -ne 0 ]; then
    echo "Failed to update package index. Please check your internet connection or sources."
    exit 1
fi

# Install xfce4-panel (dependency for plugins)
echo "Ensuring xfce4-panel is installed..."
apt-get install -y xfce4-panel
if [ $? -ne 0 ]; then
    echo "Failed to install xfce4-panel. Aborting."
    exit 1
fi

# Install plugins
echo "Installing selected Xfce4 panel plugins..."
for plugin in "${PLUGINS[@]}"; do
    echo "Installing $plugin..."
    apt-get install -y "$plugin"
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to install $plugin. It may not be available in your repository."
    else
        echo "$plugin installed successfully."
    fi
done

# Verify installation
echo "Verifying installed plugins..."
for plugin in "${PLUGINS[@]}"; do
    if dpkg -l | grep -q "$plugin"; then
        echo "$plugin is installed."
    else
        echo "$plugin is not installed."
    fi
done

# Clean up
echo "Cleaning up..."
apt-get autoremove -y
apt-get autoclean

echo "Installation complete! To add plugins to your panel:"
echo "1. Right-click the panel > Panel > Add New Items."
echo "2. Select the desired plugin and click Add."
echo "3. Configure plugins via right-click > Properties."
echo "Note: For xfce4-weather-plugin, you may need to set up an API key (e.g., from OpenWeatherMap)."

exit 0
