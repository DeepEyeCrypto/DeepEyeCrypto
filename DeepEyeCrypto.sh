#!/data/data/com.termux/files/usr/bin/bash

# Script to START and STOP XFCE4 with macOS theme on Termux-X11

case "$1" in
  start)
    echo "Starting XFCE4 with macOS Theme..."

    # Grant Storage Permissions
    termux-setup-storage

    # Update and Install Required Repositories and Packages
    pkg update -y
    pkg install x11-repo -y
    pkg install termux-x11-nightly -y
    pkg install pulseaudio -y
    pkg install wget -y
    pkg install xfce4 -y
    pkg install tur-repo -y
    pkg install firefox -y
    pkg install git -y
    pkg install gtk2 gtk3 xfce4-settings plank -y

    # Kill open X11 processes
    kill -9 $(pgrep -f "termux.x11") 2>/dev/null

    # Enable PulseAudio over Network
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

    # Prepare termux-x11 session
    export XDG_RUNTIME_DIR=${TMPDIR}
    termux-x11 :0 >/dev/null &

    # Wait until termux-x11 starts
    sleep 3

    # Launch Termux X11 main activity
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
    sleep 1

    # Set audio server
    export PULSE_SERVER=127.0.0.1

    # Apply macOS Theme and Icons
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"

    # Set macOS Wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "~/.wallpapers/macos-default.jpg"

    # Enable macOS Dock
    mkdir -p ~/.config/autostart
    echo "[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Start Plank dock" > ~/.config/autostart/plank.desktop

    plank &

    # Run XFCE4 Desktop
    env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

    echo "XFCE4 with macOS theme started successfully!"
    ;;

  stop)
    echo "Stopping XFCE4 and related services..."

    # Kill XFCE4 Session
    pkill xfce4-session

    # Kill X11 Processes
    kill -9 $(pgrep -f "termux.x11") 2>/dev/null

    # Stop PulseAudio
    pulseaudio --kill

    # Stop Plank Dock
    pkill plank

    echo "XFCE4 and related services stopped successfully!"
    ;;

  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

exit 0
