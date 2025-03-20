#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print messages in color
print_msg() {
    color=$1
    msg=$2
    echo -e "${color}${msg}${NC}"
}

# Install required packages
print_msg $BLUE "Updating packages..."
pkg update -y
print_msg $BLUE "Installing required packages..."
pkg install -y wget tar x11-repo
pkg install -y xfce4 xfce4-terminal xfce4-genmon-plugin

# Define paths
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"
CURSOR_DIR="$HOME/.icons"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
GENMON_SCRIPT_DIR="$HOME/.config/xfce4/genmon-scripts"

# Create directories
print_msg $BLUE "Creating necessary directories..."
mkdir -p $ICON_DIR $THEME_DIR $CURSOR_DIR $WALLPAPER_DIR $GENMON_SCRIPT_DIR

# Install icons
print_msg $YELLOW "Installing icons..."
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/6791955fe41d761d997a257496963514b01e7bea/01-WhiteSur.tar.xz -O icons.tar.xz
tar -xf icons.tar.xz -C $ICON_DIR
rm -f icons.tar.xz

# Install themes
declare -a theme_urls=(
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark-solid-nord.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Light.tar.xz"
)

for url in "${theme_urls[@]}"; do
    print_msg $YELLOW "Installing theme: $(basename $url)"
    wget -q $url -O theme.tar.xz
    tar -xf theme.tar.xz -C $THEME_DIR
    rm -f theme.tar.xz
done

# Install wallpapers
declare -a wallpaper_urls=(
    "https://github.com/vinceliuice/WhiteSur-wallpapers/blob/main/4k/Monterey-dark.jpg"
    "https://github.com/vinceliuice/WhiteSur-wallpapers/blob/main/4k/WhiteSur-dark.jpg"
    "https://github.com/vinceliuice/WhiteSur-wallpapers/blob/main/4k/Ventura-dark.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg"
    "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg"
    "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg"
)

for url in "${wallpaper_urls[@]}"; do
    if [[ $url == *"github.com"* ]]; then
        url="${url/github.com\/vinceliuice\/WhiteSur-wallpapers\/blob/raw.githubusercontent.com\/vinceliuice\/WhiteSur-wallpapers}"
    fi
    
    filename=$(basename $url)
    print_msg $YELLOW "Downloading wallpaper: $filename"
    wget -q --show-progress $url -O "$WALLPAPER_DIR/$filename"
done

# Install new cursor themes
declare -a cursor_urls=(
    "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/WinSur-dark-cursors.tar.gz"
    "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/Naroz-vr2b-Linux.zip"
)

for url in "${cursor_urls[@]}"; do
    print_msg $YELLOW "Installing cursor theme: $(basename $url)"
    wget -q $url -O cursor.tar.gz
    tar -xf cursor.tar.gz -C $CURSOR_DIR
    rm -f cursor.tar.gz
done

# Install dock plank
print_msg $YELLOW "Installing dock plank..."
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/mcOS-BS-Extra-Icons.zip -O dock_plank.zip
unzip -q dock_plank.zip -d $ICON_DIR
rm -f dock_plank.zip

# Configure clock widget
print_msg $BLUE "Creating clock widget..."
cat > $GENMON_SCRIPT_DIR/clock.sh <<EOF
#!/bin/bash
echo "<txt> \$(date +'%a %d %b %H:%M') </txt>"
echo "<tool>Calendar</tool>"
EOF

chmod +x $GENMON_SCRIPT_DIR/clock.sh

# Apply theme settings
print_msg $BLUE "Applying theme settings..."
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark-solid-nord"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark-solid-nord"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "WhiteSur-cursors"

# Set wallpaper
first_wallpaper=$(ls $WALLPAPER_DIR | head -n 1)
print_msg $BLUE "Setting wallpaper..."
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_DIR/$first_wallpaper"

# Add clock widget to panel
print_msg $BLUE "Configuring clock widget..."
plugin_ids=$(xfconf-query -c xfce4-panel -p /plugins/plugin-ids | sed 's/[^0-9]/ /g')
last_id=$(echo $plugin_ids | awk '{print $NF}')
new_id=$((last_id + 1))

xfconf-query -c xfce4-panel -p /plugins/plugin-ids -t int -t int -t int -t int -t int -t int -t int -s ${plugin_ids} -s $new_id
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id -n -t string -s "genmon"
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id/command -n -t string -s "sh $GENMON_SCRIPT_DIR/clock.sh"
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id/padding -n -t int -s 5
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id/refresh-rate -n -t int -s 1

# Restart panel to apply changes
print_msg $GREEN "Restarting panel to apply changes..."
xfce4-panel --restart

print_msg $GREEN "Installation complete! Your macOS-style theme with clock widget is ready."
