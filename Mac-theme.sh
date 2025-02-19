#!/bin/bash

# Update and install necessary packages
sudo apt update
sudo apt install -y xfce4 xfce4-goodies plank

# Download and install the Mac OS theme
THEME_URL="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
ICON_URL="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
CURSOR_URL="https://github.com/vinceliuice/WhiteSur-cursors.git"

# Create a directory for the themes
mkdir -p ~/themes
cd ~/themes

# Clone the theme repositories
git clone $THEME_URL
git clone $ICON_URL
git clone $CURSOR_URL

# Install the themes
cd WhiteSur-gtk-theme
./install.sh

cd ../WhiteSur-icon-theme
./install.sh

cd ../WhiteSur-cursors
./install.sh

# Apply the theme and icons
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "WhiteSur-cursors"

# Set up Plank dock
plank --preferences

# Configure XFCE panel
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=8;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-1/size -s "40"
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -t int -a -s "1" -s "2" -s "3" -s "4" -s "5"

# Add panel plugins
xfconf-query -c xfce4-panel -p /plugins/plugin-1 -t string -s "applicationsmenu"
xfconf-query -c xfce4-panel -p /plugins/plugin-2 -t string -s "tasklist"
xfconf-query -c xfce4-panel -p /plugins/plugin-3 -t string -s "separator"
xfconf-query -c xfce4-panel -p /plugins/plugin-4 -t string -s "systray"
xfconf-query -c xfce4-panel -p /plugins/plugin-5 -t string -s "clock"

# Restart the panel
xfce4-panel -r

echo "Mac OS-like theme applied successfully!"
