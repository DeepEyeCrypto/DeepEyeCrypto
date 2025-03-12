#!/data/data/com.termux/files/usr/bin/bash

# Termux XFCE Ultimate+ Widgets Theme Installer
# Features: Widgets, Conky, Plank-like dock, and system monitors

# ... (keep previous configuration and functions)

install_dependencies() {
    echo "📦 Installing system dependencies..."
    pkg update -y && pkg install -y \
        git wget curl python libsass \
        x11-repo termux-x11-nightly \
        xfce4-settings xfce4-panel-profiles \
        imagemagick fontconfig scrot jq \
        xfce4-taskmanager \
        # Additional widgets and plugins
        xfce4-cpufreq-plugin \
        xfce4-systemload-plugin \
        xfce4-battery-plugin \
        xfce4-clipman-plugin \
        xfce4-netload-plugin \
        xfce4-whiskermenu-plugin \
        xfce4-pulseaudio-plugin \
        # Conky system monitor
        conky \
        # Plank-like dock dependencies
        xfce4-docklike-plugin \
        # Weather widget dependencies
        curl jq && pip install pytz tzlocal || die "Failed to install packages"
}

configure_xfce() {
    echo "🖥  Configuring XFCE desktop with widgets..."
    local dpi=$(calculate_dpi)
    local font_size=$(( dpi > 140 ? 10 : 9 ))

    # Create custom widget panel layout
    cat > /tmp/panel.xml << 'EOF'
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugins" type="array">
        <value type="string" value="whiskermenu"/>
        <value type="string" value="tasklist"/>
        <value type="string" value="separator"/>
        <value type="string" value="systray"/>
        <value type="string" value="pulseaudio"/>
        <value type="string" value="cpufreq"/>
        <value type="string" value="systemload"/>
        <value type="string" value="netload"/>
        <value type="string" value="battery"/>
        <value type="string" value="clock"/>
        <value type="string" value="actions"/>
      </property>
    </property>
  </property>
</channel>
EOF

    xfce4-panel-profiles load /tmp/panel.xml

    # Configure conky system monitor
    cat > ${HOME}/.conkyrc << 'EOF'
conky.config = {
    alignment = 'top_right',
    background = true,
    border_width = 1,
    cpu_avg_samples = 2,
    default_color = 'white',
    default_outline_color = 'white',
    default_shade_color = 'white',
    draw_borders = false,
    draw_graph_borders = true,
    draw_outline = false,
    draw_shades = false,
    use_xft = true,
    font = 'SF Pro:size=10',
    gap_x = 20,
    gap_y = 40,
    minimum_height = 200,
    minimum_width = 250,
    net_avg_samples = 2,
    no_buffers = true,
    out_to_console = false,
    out_to_stderr = false,
    extra_newline = false,
    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_argb_visual = true,
    own_window_argb_value = 150,
    stippled_borders = 0,
    update_interval = 1.0,
    uppercase = false,
    use_spacer = 'none',
    show_graph_scale = false,
    show_graph_range = false
}

conky.text = [[
${color}SYSTEM ${hr 1}
${color}Host: $alignr$nodename
${color}OS: $alignr${exec termux-info | grep 'termux-packages' | cut -d '/' -f4}
${color}Kernel: $alignr$machine

${color}CPU ${hr 1}
${color}Frequency: $alignr${freq_g} GHz
${color}Usage: $alignr${cpu}%
${cpubar}

${color}MEMORY ${hr 1}
${color}RAM: $alignr$mem / $memmax
${membar}

${color}STORAGE ${hr 1}
${color}Root: $alignr${fs_used /} / ${fs_size /}
${fs_bar /}
]]
EOF

    # Configure weather widget (requires API key)
    mkdir -p ${HOME}/.config/xfce4/weather
    cat > ${HOME}/.config/xfce4/weather/weather.json << 'EOF'
{
    "api-key": "YOUR_OPENWEATHER_API_KEY",
    "city-id": "524901",  # Moscow by default
    "units": "metric",
    "refresh-interval": 30
}
EOF
}

# Add dock-like panel configuration
configure_dock() {
    echo "🚢 Configuring application dock..."
    mkdir -p ${HOME}/.local/share/xfce4-docklike
    cat > ${HOME}/.local/share/xfce4-docklike/config << 'EOF'
{
    "icon-size": 48,
    "items": [
        "exo-terminal-emulator.desktop",
        "exo-file-manager.desktop",
        "exo-web-browser.desktop"
    ],
    "theme": "macos",
    "hover-effect": true,
    "hide-delay": 300
}
EOF

    xfconf-query -c xfce4-panel -p /plugins/plugin-15 -s docklike
}

# ... (keep previous setup_wallpapers and validate_installation)

# Main Execution
check_android_version
install_dependencies
backup_config
install_fonts
install_theme
configure_xfce
configure_dock
setup_wallpapers
validate_installation
cleanup
