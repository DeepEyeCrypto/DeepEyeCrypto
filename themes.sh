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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_msg $RED "Please don't run this script as root!"
    exit 1
fi

# Install required packages
print_msg $BLUE "Updating package list..."
pkg update -y || { print_msg $RED "Failed to update packages"; exit 1; }
print_msg $BLUE "Installing required packages..."
pkg install -y wget tar unzip x11-repo curl jq || { print_msg $RED "Failed to install basic packages"; exit 1; }
pkg install -y xfce4 xfce4-terminal xfce4-genmon-plugin thunar || { print_msg $RED "Failed to install XFCE packages"; exit 1; }

# Define paths
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"
CURSOR_DIR="$HOME/.icons"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
GENMON_SCRIPT_DIR="$HOME/.config/xfce4/genmon-scripts"
DESKTOP_ICON_DIR="$HOME/Desktop"

# Create directories
print_msg $BLUE "Creating necessary directories..."
mkdir -p $ICON_DIR $THEME_DIR $CURSOR_DIR $WALLPAPER_DIR $GENMON_SCRIPT_DIR $DESKTOP_ICON_DIR

# Function to download and verify
download_and_extract() {
    url=$1
    dest_dir=$2
    filename=$(basename $url)
    max_attempts=3
    attempt=1

    while [ $attempt -le $max_attempts ]; do
        print_msg $YELLOW "Downloading $filename (Attempt $attempt/$max_attempts)..."
        wget -q --show-progress $url -O "$filename"
        
        # Check if file exists and is not empty
        if [ -s "$filename" ]; then
            print_msg $BLUE "Verifying $filename..."
            if tar -tzf "$filename" >/dev/null 2>&1; then
                print_msg $GREEN "Extracting $filename to $dest_dir..."
                tar -xzf "$filename" -C "$dest_dir" || { print_msg $RED "Failed to extract $filename"; rm -f "$filename"; exit 1; }
                rm -f "$filename"
                return 0
            else
                print_msg $RED "File $filename is corrupt or incomplete"
                rm -f "$filename"
            fi
        else
            print_msg $RED "Download failed: $filename is empty or not downloaded"
            rm -f "$filename" 2>/dev/null
        fi
        
        attempt=$((attempt + 1))
        [ $attempt -le $max_attempts ] && print_msg $YELLOW "Retrying in 2 seconds..." && sleep 2
    done
    
    print_msg $RED "Failed to download/extract $filename after $max_attempts attempts"
    exit 1
}

# Install icons
print_msg $YELLOW "Installing WhiteSur icons..."
download_and_extract "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/6791955fe41d761d997a257496963514b01e7bea/01-WhiteSur.tar.xz" "$ICON_DIR"

# Install custom desktop icons
print_msg $YELLOW "Installing custom desktop icons..."
declare -a desktop_icon_sets=(
    "https://github.com/yeyushengfan258/RevengeOS-Icon-Pack/raw/master/RevengeOS-macOS.tar.gz"
    "https://github.com/vinceliuice/Qogir-icon-theme/raw/master/Qogir-manjaro.tar.gz"
    "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/tags/20230104.tar.gz"
)

for url in "${desktop_icon_sets[@]}"; do
    download_and_extract "$url" "$ICON_DIR"
done

# Create desktop launchers
print_msg $BLUE "Creating desktop launchers..."
cat > "$DESKTOP_ICON_DIR/Terminal.desktop" <<EOF
[Desktop Entry]
Name=Terminal
Exec=xfce4-terminal
Type=Application
Icon=Qogir-manjaro/applications-terminal
Terminal=false
EOF

cat > "$DESKTOP_ICON_DIR/Settings.desktop" <<EOF
[Desktop Entry]
Name=Settings
Exec=xfce4-settings-manager
Type=Application
Icon=RevengeOS-macOS/applications-system
Terminal=false
EOF

cat > "$DESKTOP_ICON_DIR/FileManager.desktop" <<EOF
[Desktop Entry]
Name=Files
Exec=thunar
Type=Application
Icon=papirus-icon-theme-20230104/folder
Terminal=false
EOF

chmod +x "$DESKTOP_ICON_DIR"/*.desktop

# Install themes
print_msg $YELLOW "Installing themes..."
declare -a theme_urls=(
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark-solid-nord.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Light.tar.xz"
)

for url in "${theme_urls[@]}"; do
    download_and_extract "$url" "$THEME_DIR"
done

# Install wallpapers
print_msg $YELLOW "Installing wallpapers..."
declare -a wallpaper_urls=(
    "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/Monterey-dark.jpg"
    "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/WhiteSur-dark.jpg"
    "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/Ventura-dark.jpg"
    "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg"
)

for url in "${wallpaper_urls[@]}"; do
    filename=$(basename $url)
    print_msg $YELLOW "Downloading wallpaper: $filename"
    wget -q --show-progress $url -O "$WALLPAPER_DIR/$filename" || print_msg $YELLOW "Warning: Failed to download $filename"
done

# Install cursor themes
print_msg $YELLOW "Installing cursor themes..."
declare -a cursor_urls=(
    "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/WinSur-dark-cursors.tar.gz"
    "https://github.com/vinceliuice/Qogir-theme/raw/master/src/cursors/Qogir-cursors.tar.gz"
    "https://github.com/ful1e5/apple_cursor/releases/download/v2.0.0/macOS-Monterey.tar.gz"
)

for url in "${cursor_urls[@]}"; do
    download_and_extract "$url" "$CURSOR_DIR"
done

# Install dock plank
print_msg $YELLOW "Installing dock plank..."
wget -q --show-progress https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/mcOS-BS-Extra-Icons.zip -O dock_plank.zip
unzip -q dock_plank.zip -d $ICON_DIR || { print_msg $RED "Failed to extract dock plank"; exit 1; }
rm -f dock_plank.zip

# Install panel clock widget
print_msg $BLUE "Creating panel clock widget..."
cat > $GENMON_SCRIPT_DIR/clock.sh <<EOF
#!/bin/bash
echo "<txt> \$(date +'%A, %d %B %Y  %I:%M:%S %p') </txt>"
echo "<tool>Full Date and Time</tool>"
EOF
chmod +x $GENMON_SCRIPT_DIR/clock.sh

# Install system monitor widget
print_msg $BLUE "Creating system monitor widget..."
cat > $GENMON_SCRIPT_DIR/sysmon.sh <<EOF
#!/bin/bash
CPU=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2}' | cut -d. -f1)
MEM=\$(free -h | awk '/^Mem:/ {print \$3 "/" \$2}')
DISK=\$(df -h / | awk 'NR==2 {print \$3 "/" \$2}')
echo "<txt> CPU: \$CPU% | RAM: \$MEM | Disk: \$DISK </txt>"
echo "<tool>System Monitor</tool>"
EOF
chmod +x $GENMON_SCRIPT_DIR/sysmon.sh

# Install weather widget
print_msg $BLUE "Creating weather widget script..."
cat > $GENMON_SCRIPT_DIR/weather.sh <<EOF
#!/bin/bash
# Replace YOUR_API_KEY and YOUR_CITY_ID with actual values
API_KEY="YOUR_API_KEY"
CITY_ID="YOUR_CITY_ID"
WEATHER_DATA=\$(curl -s "http://api.openweathermap.org/data/2.5/weather?id=\$CITY_ID&appid=\$API_KEY&units=metric")
TEMP=\$(echo \$WEATHER_DATA | jq -r '.main.temp')
DESC=\$(echo \$WEATHER_DATA | jq -r '.weather[0].description')
echo "<txt> Weather: \$TEMP°C, \$DESC </txt>"
echo "<tool>Current weather conditions</tool>"
EOF
chmod +x $GENMON_SCRIPT_DIR/weather.sh

# Apply theme settings
print_msg $BLUE "Applying theme settings..."
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark-solid-nord"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark-solid-nord"
xfconf-query -c xsettings -p /Net/IconThemeName -s "RevengeOS-macOS"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "macOS-Monterey"

# Set wallpaper
first_wallpaper=$(ls $WALLPAPER_DIR | head -n 1)
if [ -n "$first_wallpaper" ]; then
    print_msg $BLUE "Setting wallpaper..."
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_DIR/$first_wallpaper"
fi

# Configure panel widgets
print_msg $BLUE "Configuring panel widgets..."
plugin_ids=$(xfconf-query -c xfce4-panel -p /plugins/plugin-ids | sed 's/[^0-9]/ /g' || echo "1 2 3 4 5")
last_id=$(echo $plugin_ids | awk '{print $NF}')

# Clock widget
clock_id=$((last_id + 1))
xfconf-query -c xfce4-panel -p /plugins/plugin-ids -t int -t int -t int -t int -t int -t int -t int -s ${plugin_ids} -s $clock_id
xfconf-query -c xfce4-panel -p /plugins/plugin-$clock_id -n -t string -s "genmon"
xfconf-query -c xfce4-panel -p /plugins/plugin-$clock_id/command -n -t string -s "sh $GENMON_SCRIPT_DIR/clock.sh"
xfconf-query -c xfce4-panel -p /plugins/plugin-$clock_id/padding -n -t int -s 5
xfconf-query -c xfce4-panel -p /plugins/plugin-$clock_id/refresh-rate -n -t int -s 1

# System monitor widget
sysmon_id=$((last_id + 2))
xfconf-query -c xfce4-panel -p /plugins/plugin-ids -t int -t int -t int -t int -t int -t int -t int -t int -s ${plugin_ids} -s $clock_id -s $sysmon_id
xfconf-query -c xfce4-panel -p /plugins/plugin-$sysmon_id -n -t string -s "genmon"
xfconf-query -c xfce4-panel -p /plugins/plugin-$sysmon_id/command -n -t string -s "sh $GENMON_SCRIPT_DIR/sysmon.sh"
xfconf-query -c xfce4-panel -p /plugins/plugin-$sysmon_id/padding -n -t int -s 5
xfconf-query -c xfce4-panel -p /plugins/plugin-$sysmon_id/refresh-rate -n -t int -s 5

# Weather widget
weather_id=$((last_id + 3))
xfconf-query -c xfce4-panel -p /plugins/plugin-ids -t int -t int -t int -t int -t int -t int -t int -t int -t int -s ${plugin_ids} -s $clock_id -s $sysmon_id -s $weather_id
xfconf-query -c xfce4-panel -p /plugins/plugin-$weather_id -n -t string -s "genmon"
xfconf-query -c xfce4-panel -p /plugins/plugin-$weather_id/command -n -t string -s "sh $GENMON_SCRIPT_DIR/weather.sh"
xfconf-query -c xfce4-panel -p /plugins/plugin-$weather_id/padding -n -t int -s 5
xfconf-query -c xfce4-panel -p /plugins/plugin-$weather_id/refresh-rate -n -t int -s 300

# Restart panel and desktop
print_msg $GREEN "Restarting panel and desktop to apply changes..."
xfce4-panel --restart || print_msg $YELLOW "Panel restart failed, please restart manually"
killall xfdesktop && xfdesktop &

print_msg $GREEN "Installation complete! Your desktop now has widgets:"
print_msg $YELLOW "- Panel Clock Widget"
print_msg $YELLOW "- Panel System Monitor Widget"
print_msg $YELLOW "- Panel Weather Widget (edit weather.sh with API key and city ID)"
print_msg $YELLOW "To get weather working:"
print_msg $YELLOW "1. Get API key from openweathermap.org"
print_msg $YELLOW "2. Find your city ID"
print_msg $YELLOW "3. Edit $GENMON_SCRIPT_DIR/weather.sh"
