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

    # Install macOS Themes and Icons
    echo "Installing macOS Themes and Icons..."
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh
    cd ..

    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh
    cd ..

    # Install macOS Wallpapers
    echo "Installing macOS Wallpapers..."
    git clone https://github.com/joeyhoer/macOS-Wallpapers.git
    mkdir -p ~/.wallpapers
    cp macOS-Wallpapers/* ~/.wallpapers/

    # Apply macOS Theme and Icons
    xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"

    # Set Multiple macOS Wallpapers
    echo "Configuring Multiple Wallpapers..."
    WALLPAPER_DIR="$HOME/.wallpapers"
    WALLPAPER_FILES=($(ls $WALLPAPER_DIR/*.jpg $WALLPAPER_DIR/*.png 2>/dev/null))

    if [ ${#WALLPAPER_FILES[@]} -gt 0 ]; then
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "${WALLPAPER_FILES[0]}"
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style -s 5  # Scaled wallpaper
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-show -s true

        echo "Enabling Wallpaper Slideshow..."
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/slideshow-enabled -s true
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/slideshow-directory -s "$WALLPAPER_DIR"
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/slideshow-delay -s 300 # 5-minute delay
    else
        echo "No wallpapers found in $WALLPAPER_DIR"
    fi

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

    # Start DeepEyeCrypto Service
    if [ -f "./DeepEyeCrypto.sh" ]; then
        chmod +x ./DeepEyeCrypto.sh
        echo "Starting DeepEyeCrypto Service..."
        ./DeepEyeCrypto.sh start
        if [ $? -eq 0 ]; then
            echo "DeepEyeCrypto service started successfully!"
        else
            echo "Failed to start DeepEyeCrypto service. Check the script for errors."
        fi
    else
        echo "DeepEyeCrypto.sh not found. Skipping DeepEyeCrypto service startup."
    fi

    echo "XFCE4 with macOS themes, icons, and multiple wallpapers started successfully!"
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

    # Stop DeepEyeCrypto Service
    if [ -f "./DeepEyeCrypto.sh" ]; then
        echo "Stopping DeepEyeCrypto Service..."
        ./DeepEyeCrypto.sh stop
        if [ $? -eq 0 ]; then
            echo "DeepEyeCrypto service stopped successfully!"
        else
            echo "Failed to stop DeepEyeCrypto service. Check the script for errors."
        fi
    else
        echo "DeepEyeCrypto.sh not found. Skipping DeepEyeCrypto service shutdown."
    fi

    echo "XFCE4 and related services stopped successfully!"
    ;;

  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

exit 0
