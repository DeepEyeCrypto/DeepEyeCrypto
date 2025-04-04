#!/data/data/com.termux/files/usr/bin/bash

# Define directories
THEME_DIR="$HOME/.themes"
ICON_DIR="$HOME/.icons"
WALLPAPER_DIR="$PREFIX/share/backgrounds/xfce"
TEMP_DIR="$HOME/temp_xfce_setup"

# Exit on error
set -e

# Create directories if they don't exist
mkdir -p "$THEME_DIR" "$ICON_DIR" "$WALLPAPER_DIR" "$TEMP_DIR"

# Update and install dependencies
echo "Updating Termux and installing dependencies..."
pkg update -y && pkg upgrade -y || { echo "Package update failed"; exit 1; }
pkg install x11-repo -y
pkg install termux-x11-nightly xfce4 xfce4-goodies git wget unzip tar -y || { echo "Package installation failed"; exit 1; }
pkg install gtk2-engines-murrine gtk3-engines -y

# Download and install Themes
echo "Installing Themes..."
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark-solid-nord.tar.xz" || echo "Failed to download WhiteSur-Dark-solid-nord"
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Dark.tar.xz" || echo "Failed to download WhiteSur-Dark"
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/refs/heads/master/release/WhiteSur-Light.tar.xz" || echo "Failed to download WhiteSur-Light"
for tarfile in "$TEMP_DIR"/*.tar.xz; do
    [ -f "$tarfile" ] && tar -xJf "$tarfile" -C "$THEME_DIR" || echo "Failed to extract $tarfile"
done

# Download and install Icons
echo "Installing Icons..."
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/6791955fe41d761d997a257496963514b01e7bea/01-WhiteSur.tar.xz" || echo "Failed to download WhiteSur icons"
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/mcOS-BS-Extra-Icons.zip" || echo "Failed to download mcOS-BS-Extra-Icons"
[ -f "$TEMP_DIR/01-WhiteSur.tar.xz" ] && tar -xJf "$TEMP_DIR/01-WhiteSur.tar.xz" -C "$ICON_DIR" || echo "Failed to extract WhiteSur icons"
[ -f "$TEMP_DIR/mcOS-BS-Extra-Icons.zip" ] && unzip -o "$TEMP_DIR/mcOS-BS-Extra-Icons.zip" -d "$ICON_DIR" || echo "Failed to extract mcOS-BS-Extra-Icons"

# Download and install Cursor Themes
echo "Installing Cursor Themes..."
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/WinSur-dark-cursors.tar.gz" || echo "Failed to download WinSur-dark-cursors"
wget -q --show-progress -P "$TEMP_DIR" "https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/Naroz-vr2b-Linux.zip" || echo "Failed to download Naroz-vr2b-Linux"
[ -f "$TEMP_DIR/WinSur-dark-cursors.tar.gz" ] && tar -xzf "$TEMP_DIR/WinSur-dark-cursors.tar.gz" -C "$ICON_DIR" || echo "Failed to extract WinSur-dark-cursors"
[ -f "$TEMP_DIR/Naroz-vr2b-Linux.zip" ] && unzip -o "$TEMP_DIR/Naroz-vr2b-Linux.zip" -d "$ICON_DIR" || echo "Failed to extract Naroz-vr2b-Linux"

# Download Wallpapers
echo "Installing Wallpapers..."
wget -q --show-progress -P "$WALLPAPER_DIR" "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/Monterey-dark.jpg" || echo "Failed to download Monterey-dark"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/WhiteSur-dark.jpg" || echo "Failed to download WhiteSur-dark"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://github.com/vinceliuice/WhiteSur-wallpapers/raw/main/4k/Ventura-dark.jpg" || echo "Failed to download Ventura-dark"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://4kwallpapers.com/images/wallpapers/macos-big-sur-apple-layers-fluidic-colorful-wwdc-stock-4096x2304-1455.jpg" -O "$WALLPAPER_DIR/macos-big-sur.jpg" || echo "Failed to download macos-big-sur"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://4kwallpapers.com/images/wallpapers/macos-fusion-8k-7680x4320-12482.jpg" -O "$WALLPAPER_DIR/macos-fusion.jpg" || echo "Failed to download macos-fusion"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11577.jpeg" -O "$WALLPAPER_DIR/macos-sonoma-1.jpeg" || echo "Failed to download macos-sonoma-1"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://4kwallpapers.com/images/wallpapers/macos-sonoma-6016x6016-11576.jpeg" -O "$WALLPAPER_DIR/macos-sonoma-2.jpeg" || echo "Failed to download macos-sonoma-2"
wget -q --show-progress -P "$WALLPAPER_DIR" "https://4kwallpapers.com/images/wallpapers/sierra-nevada-mountains-macos-high-sierra-mountain-range-5120x2880-8674.jpg" -O "$WALLPAPER_DIR/macos-high-sierra.jpg" || echo "Failed to download macos-high-sierra"

# XFCE Startup Script
echo "Creating XFCE startup script..."
cat > "$HOME/start-xfce.sh" << EOL
#!/data/data/com.termux/files/usr/bin/bash
termux-x11 :1 &
sleep 2
export DISPLAY=:1
xfce4-session
EOL
chmod +x "$HOME/start-xfce.sh"

# XFCE Configuration
echo "Configuring XFCE..."
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
    <property name="backdrop" type="empty">
        <property name="screen0" type="empty">
            <property name="monitor0" type="empty">
                <property name="workspace0" type="empty">
                    <property name="color-style" type="int" value="0"/>
                    <property name="image-style" type="int" value="5"/>
                    <property name="last-image" type="string" value="$WALLPAPER_DIR/Monterey-dark.jpg"/>
                </property>
            </property>
        </property>
    </property>
</channel>
EOL

cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
    <property name="general" type="empty">
        <property name="theme" type="string" value="WhiteSur-Dark"/>
        <property name="title_font" type="string" value="Sans Bold 10"/>
    </property>
</channel>
EOL

cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
    <property name="Net" type="empty">
        <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
        <property name="IconThemeName" type="string" value="WhiteSur"/>
        <property name="CursorThemeName" type="string" value="WinSur-dark-cursors"/>
    </property>
    <property name="Gtk" type="empty">
        <property name="FontName" type="string" value="Sans 10"/>
    </property>
</channel>
EOL

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Setup complete!"
echo "Run './start-xfce.sh' to start XFCE"
echo "Ensure Termux:X11 app is installed and running"
