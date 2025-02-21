#!/bin/bash

# macOS Theming Suite for Termux XFCE

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create configuration directories
mkdir -p "$HOME/.fonts" \
         "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml" \
         "$HOME/.config/gtk-3.0" \
         "$HOME/.config/xfce4/terminal"

# Install core packages
echo -e "${BLUE}Installing required packages...${NC}"
pkg install -y papirus-icon-theme mesalib vulkan-icd-loader unzip

# macOS Wallpaper Installation
echo -e "${BLUE}Downloading macOS wallpapers...${NC}"
mkdir -p $PREFIX/share/backgrounds/xfce/
wget -q -P $PREFIX/share/backgrounds/xfce/ \
    https://raw.githubusercontent.com/termux/xfce-themes/macos/Mojave-Dynamic.jpg \
    https://raw.githubusercontent.com/termux/xfce-themes/macos/Monterery-Dark.jpeg \
    https://raw.githubusercontent.com/termux/xfce-themes/macos/Big-Sur-Light.jpg \
    https://raw.githubusercontent.com/termux/xfce-themes/macos/Ventura-Night.jpg

# GTK Theme Installation
echo -e "${BLUE}Installing macOS GTK themes...${NC}"

# WhiteSur Theme
wget -q https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/2023-04-26.zip
unzip -q 2023-04-26.zip
tar -xf WhiteSur-gtk-theme-2023-04-26/release/WhiteSur-Dark-44-0.tar.xz
mv WhiteSur-Dark/ $PREFIX/share/themes/

# McMojave Theme
wget -q https://github.com/vinceliuice/McMojave-circle/archive/refs/tags/2023-06-15.zip
unzip -q 2023-06-15.zip
mv McMojave-circle-2023-06-15/McMojave-circle-Dark $PREFIX/share/themes/

# Monterey Theme
wget -q https://github.com/vinceliuice/Monterey-gtk-theme/archive/refs/tags/2023-05-01.zip
unzip -q 2023-05-01.zip
mv Monterey-gtk-theme-2023-05-01/Monterey-Dark $PREFIX/share/themes/

# Cursor Themes
echo -e "${BLUE}Installing macOS-style cursors...${NC}"

# Fluent Cursors
wget -q https://github.com/vinceliuice/Fluent-icon-theme/archive/2023-02-01.zip
unzip -q 2023-02-01.zip
mkdir -p $PREFIX/share/icons/
mv Fluent-icon-theme-2023-02-01/cursors/dist* $PREFIX/share/icons/

# Capitaine Cursors
wget -q https://github.com/keeferrourke/capitaine-cursors/releases/download/r5.0.0/capitaine-cursors-r5.0.0.tar.bz2
tar -xjf capitaine-cursors-r5.0.0.tar.bz2
mv capitaine-cursors/ $PREFIX/share/icons/

# XFCE Configuration
echo -e "${BLUE}Configuring XFCE desktop...${NC}"

# XSettings Configuration
cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="capitaine-cursors"/>
    <property name="CursorThemeSize" type="int" value="28"/>
  </property>
</channel>
EOF

# Window Manager Configuration
cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="WhiteSur-Dark"/>
    <property name="title_alignment" type="string" value="center"/>
  </property>
</channel>
EOF

# Panel Styling
cat <<'EOF' > $HOME/.config/gtk-3.0/gtk.css
.xfce4-panel {
   border-top-left-radius: 10px;
   border-top-right-radius: 10px;
   background-color: rgba(255, 255, 255, 0.1);
}
EOF

# Font Installation
echo -e "${BLUE}Installing macOS-style fonts...${NC}"
wget -q https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip
unzip -q CascadiaCode-2111.01.zip
mv otf/static/*.ttf $HOME/.fonts/

wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
unzip -q Meslo.zip -d $HOME/.fonts/

# Terminal Configuration
echo -e "${BLUE}Setting up terminal emulator...${NC}"
cat <<'EOF' > $HOME/.config/xfce4/terminal/terminalrc
[Configuration]
ColorPalette=#000000;#cc0000;#4e9a06;#c4a000;#3465a4;#75507b;#06989a;#d3d7cf;#555753;#ef2929;#8ae234;#fce94f;#739fcf;#ad7fa8;#34e2e2;#eeeeec
FontName=MesloLGS NF 12
EOF

# Cleanup
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -rf WhiteSur* McMojave* Monterey* Fluent* capitaine* 
rm -rf 2023*.zip *.tar.bz2 Cascadia* Meslo.zip

echo -e "${GREEN}\nmacOS Theming Suite installed successfully!${NC}"
echo -e "Included components:"
echo -e "  - 3 GTK Themes: WhiteSur-Dark, McMojave-Dark, Monterey-Dark"
echo -e "  - 2 Cursor Packs: Fluent & Capitaine"
echo -e "  - 4 macOS Wallpapers (Mojave, Monterey, Big Sur, Ventura)"
echo -e "  - System Fonts: Cascadia Code + Meslo Nerd Font"
echo -e "\nTo customize:"
echo -e "  1. Open Appearance settings to change themes"
echo -e "  2. Mouse settings to change cursor theme"
echo -e "  3. Background settings to select wallpaper"
echo -e "  4. Terminal preferences to adjust font/size\n"
