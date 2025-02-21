#!/bin/bash

# Theming Section for Termux XFCE

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

# Install theme-related packages
echo -e "${BLUE}Installing theme packages...${NC}"
pkg install -y papirus-icon-theme mesalib vulkan-icd-loader

# Download and apply wallpaper
echo -e "${BLUE}Setting up wallpaper...${NC}"
wget -q https://raw.githubusercontent.com/phoenixbyrd/Termux_XFCE/main/dark_waves.png
mkdir -p $PREFIX/share/backgrounds/xfce/
mv dark_waves.png $PREFIX/share/backgrounds/xfce/

# Install WhiteSur-Dark Theme
echo -e "${BLUE}Installing WhiteSur-Dark theme...${NC}"
wget -q https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/2023-04-26.zip
unzip -q 2023-04-26.zip
tar -xf WhiteSur-gtk-theme-2023-04-26/release/WhiteSur-Dark-44-0.tar.xz
mv WhiteSur-Dark/ $PREFIX/share/themes/
rm -rf WhiteSur* 2023-04-26.zip

# Install Fluent Cursor Theme
echo -e "${BLUE}Installing Fluent cursor theme...${NC}"
wget -q https://github.com/vinceliuice/Fluent-icon-theme/archive/2023-02-01.zip
unzip -q 2023-02-01.zip
mkdir -p $PREFIX/share/icons/
mv Fluent-icon-theme-2023-02-01/cursors/dist* $PREFIX/share/icons/
rm -rf Fluent* 2023-02-01.zip

# Configure XFCE appearance
echo -e "${BLUE}Configuring XFCE settings...${NC}"
cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="dist-dark"/>
    <property name="CursorThemeSize" type="int" value="28"/>
  </property>
</channel>
EOF

cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="WhiteSur-Dark"/>
    <property name="title_alignment" type="string" value="center"/>
  </property>
</channel>
EOF

# Configure panel styling
echo -e "${BLUE}Setting up panel styling...${NC}"
cat <<'EOF' > $HOME/.config/gtk-3.0/gtk.css
.xfce4-panel {
   border-top-left-radius: 10px;
   border-top-right-radius: 10px;
}
EOF

# Install fonts
echo -e "${BLUE}Installing fonts...${NC}"
wget -q https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip
unzip -q CascadiaCode-2111.01.zip
mv otf/static/*.ttf $HOME/.fonts/
rm -rf otf ttf woff2 CascadiaCode*

wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
unzip -q Meslo.zip -d $HOME/.fonts/
rm Meslo.zip

# Configure terminal theme
echo -e "${BLUE}Configuring terminal...${NC}"
cat <<'EOF' > $HOME/.config/xfce4/terminal/terminalrc
[Configuration]
ColorPalette=#000000;#cc0000;#4e9a06;#c4a000;#3465a4;#75507b;#06989a;#d3d7cf;#555753;#ef2929;#8ae234;#fce94f;#739fcf;#ad7fa8;#34e2e2;#eeeeec
FontName=Cascadia Mono PL 12
EOF

echo -e "${GREEN}\nTheming setup complete! Restart XFCE to see changes.${NC}"
