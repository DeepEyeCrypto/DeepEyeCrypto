#!/bin/bash

# ... [Previous parts of the script remain the same] ...

# Create xfce4-panel.xml
cat <<'EOF' > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.1" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <value type="int" value="2"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="icon-size" type="uint" value="0"/>
      <property name="size" type="uint" value="34"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="3"/>
        <value type="int" value="10"/>
        <value type="int" value="11"/>
        <value type="int" value="9"/>
        <value type="int" value="8"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="2"/>
        <value type="int" value="7"/>
      </property>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0"/>
        <value type="double" value="0"/>
        <value type="double" value="0"/>
        <value type="double" value="0"/>
      </property>
    </property>
    <property name="panel-2" type="empty">
      <property name="autohide-behavior" type="uint" value="1"/>
      <property name="position" type="string" value="p=10;x=0;y=0"/>
      <property name="length" type="uint" value="1"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="64"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="12"/>
        <value type="int" value="4"/>
        <value type="int" value="17"/>
      </property>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.14117647058823529"/>
        <value type="double" value="0.14117647058823529"/>
        <value type="double" value="0.14117647058823529"/>
        <value type="double" value="1"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-title" type="string" value="Menu "/>
      <property name="button-icon" type="string" value="start-here"/>
      <property name="show-button-title" type="bool" value="true"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="false"/>
      <property name="style" type="uint" value="2"/>
    </property>
    <property name="plugin-5" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
      <property name="expand" type="bool" value="true"/>
    </property>
    <property name="plugin-6" type="string" value="systray">
      <property name="square-icons" type="bool" value="true"/>
      <property name="known-legacy-items" type="array">
        <value type="string" value="vesktop"/>
        <value type="string" value="onboard"/>
      </property>
    </property>
    <property name="plugin-8" type="string" value="clock">
      <property name="digital-layout" type="uint" value="3"/>
      <property name="digital-time-format" type="string" value="%H:%M"/>
      <property name="tooltip-format" type="string" value="%A %d %B %Y"/>
      <property name="show-frame" type="bool" value="false"/>
    </property>
    <property name="plugin-9" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
    </property>
    <property name="plugin-10" type="string" value="tasklist">
      <property name="grouping" type="uint" value="1"/>
    </property>
    <property name="plugin-11" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-2" type="string" value="showdesktop"/>
    <property name="plugin-7" type="string" value="power-manager-plugin"/>
    <property name="plugin-4" type="string" value="whiskermenu">
      <property name="button-title" type="string" value=" "/>
      <property name="button-icon" type="string" value="start-here"/>
    </property>
    <property name="plugin-12" type="string" value="launcher">
      <property name="items" type="string" value="firefox.desktop"/>
    </property>
    <property name="plugin-17" type="string" value="launcher">
      <property name="items" type="string" value="xfce4-terminal.desktop"/>
    </property>
  </property>
</channel>
EOF

# Continue with remaining setup
# Install Debian proot
if ! proot-distro install debian; then
    echo "Failed to install Debian proot. Exiting."
    exit 1
fi

# Create user in Debian proot
proot-distro login debian --shared-tmp -- /usr/sbin/useradd -m -G sudo -s /bin/bash "$username"
echo -e "Set password for $username:"
proot-distro login debian --shared-tmp -- passwd "$username"

# Install GPU drivers in proot
cat <<'EOF' > $TEMP_DIR/proot_setup.sh
#!/bin/bash
apt update
apt install -y mesa-utils vulkan-tools
echo "export LIBGL_ALWAYS_SOFTWARE=1" >> /etc/profile.d/00-android.sh
echo "export GALLIUM_DRIVER=virpipe" >> /etc/profile.d/00-android.sh
EOF
proot-distro login debian --user "$username" --shared-tmp -- bash < $TEMP_DIR/proot_setup.sh

# Create desktop entries
cat <<'EOF' > $HOME/Desktop/firefox.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Exec=firefox
Icon=firefox
EOF

cat <<'EOF' > $HOME/Desktop/terminal.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
EOF

# Set execute permissions
chmod +x $HOME/Desktop/*.desktop

# Final instructions
clear
echo -e "${GREEN}Installation complete!${NC}"
echo -e "\nTo start the desktop environment:"
echo -e "1. Open Termux"
echo -e "2. Run: ${YELLOW}termux-x11${NC}"
echo -e "3. In new session: ${YELLOW}pulseaudio --start && termux-x11${NC}"
echo -e "4. Finally run: ${YELLOW}xfce4-session${NC}"
echo -e "\nFor Debian proot: Run ${YELLOW}debian${NC} in terminal"
echo -e "Hardware acceleration: Run ${YELLOW}vulkaninfo${NC} in proot"

exit 0
