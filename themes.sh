#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting installation process...${NC}"

# Install required packages
echo -e "${YELLOW}Updating package list...${NC}"
pkg update -y

echo -e "${YELLOW}Installing required packages...${NC}"
pkg install -y wget tar x11-repo xfce4 xfce4-terminal xfce4-genmon-plugin

# Define paths
ICON_DIR="$HOME/.icons"
THEME_DIR="$HOME/.themes"
CURSOR_DIR="$HOME/.icons"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
GENMON_SCRIPT_DIR="$HOME/.config/xfce4/genmon-scripts"

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p $ICON_DIR $THEME_DIR $CURSOR_DIR $WALLPAPER_DIR $GENMON_SCRIPT_DIR

# Install cursor theme
echo -e "${GREEN}Installing cursor theme...${NC}"
wget -q https://github.com/vinceliuice/WhiteSur-cursors/releases/download/v1.0/WhiteSur-cursors.tar.xz -O cursors.tar.xz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download cursor theme.${NC}"
    exit 1
fi
tar -xf cursors.tar.xz -C $CURSOR_DIR
rm -f cursors.tar.xz

# Install icons
echo -e "${GREEN}Installing icons...${NC}"
wget -q https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/6791955fe41d761d997a257496963514b01e7bea/01-WhiteSur.tar.xz -O icons.tar.xz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download icons.${NC}"
    exit 1
fi
tar -xf icons.tar.xz -C $ICON_DIR
rm -f icons.tar.xz

# Install themes
declare -a theme_urls=(
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark-solid-nord.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark.tar.xz"
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Light.tar.xz"
)

echo -e "${GREEN}Installing themes...${NC}"
for url in "${theme_urls[@]}"; do
    echo -e "${YELLOW}Installing theme: $(basename $url)...${NC}"
    wget -q $url -O theme.tar.xz
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download theme: $(basename $url).${NC}"
        continue
    fi
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

echo -e "${GREEN}Installing wallpapers...${NC}"
for url in "${wallpaper_urls[@]}"; do
    if [[ $url == *"github.com"* ]]; then
        url="${url/github.com\/vinceliuice\/WhiteSur-wallpapers\/blob/raw.githubusercontent.com\/vinceliuice\/WhiteSur-wallpapers}"
    fi
    
    filename=$(basename $url)
    echo -e "${YELLOW}Downloading wallpaper: $filename...${NC}"
    wget -q --show-progress $url -O "$WALLPAPER_DIR/$filename"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download wallpaper: $filename.${NC}"
        continue
    fi
done

# Configure clock widget
echo -e "${GREEN}Creating clock widget...${NC}"
cat > $GENMON_SCRIPT_DIR/clock.sh <<EOF
#!/bin/bash
echo "<txt> \$(date +'%a %d %b %H:%M') </txt>"
echo "<tool>Calendar</tool>"
EOF

chmod +x $GENMON_SCRIPT_DIR/clock.sh

# Apply theme settings
echo -e "${GREEN}Applying theme settings...${NC}"
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark-solid-nord"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark-solid-nord"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "WhiteSur-cursors"

# Set wallpaper
first_wallpaper=$(ls $WALLPAPER_DIR | head -n 1)
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_DIR/$first_wallpaper"

# Add clock widget to panel
echo -e "${GREEN}Configuring clock widget...${NC}"
plugin_ids=$(xfconf-query -c xfce4-panel -p /plugins/plugin-ids | sed 's/[^0-9]/ /g')
last_id=$(echo $plugin_ids | awk '{print $NF}')
new_id=$((last_id + 1))

xfconf-query -c xfce4-panel -p /plugins/plugin-ids -t int -t int -t int -t int -t int -t int -t int -s ${plugin_ids} -s $new_id
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id -n -t string -s "genmon"
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id/command -n -t string -s "sh $GENMON_SCRIPT_DIR/clock.sh"
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id/padding -n -t int -s 5
xfconf-query -c xfce4-panel -p /plugins/plugin-$new_id/refresh-rate -n -t int -s 1

# Restart panel to apply changes
echo -e "${YELLOW}Restarting XFCE panel...${NC}"
xfce4-panel --restart

echo -e "${BLUE}Installation complete! Your macOS-style theme with clock widget is ready.${NC}"
