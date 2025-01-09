#!/data/data/com.termux/files/usr/bin/bash

# Setup Termux storage and update packages
termux-setup-storage
pkg update -y
pkg install x11-repo -y
pkg install termux-x11-nightly -y
pkg install pulseaudio -y
pkg install wget -y
pkg install xfce4 -y
pkg install tur-repo -y
pkg install firefox -y
pkg install git -y
pkg install figlet toilet lolcat -y

# Kill open X11 processes
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait a bit until termux-x11 gets started
sleep 3

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Set audio server
export PULSE_SERVER=127.0.0.1

# Display enhanced terminal banner
clear
echo -e "\e[1;32mStarting DeepEyeCrypto Desktop Environment...\e[0m" | lolcat
figlet -c -f big "DeepEyeCrypto" | lolcat

echo -e "\nWelcome to your secure, stylish, and powerful XFCE4 workspace!" | lolcat
echo -e "Stay productive, stay inspired.\n" | lolcat

# Download and install WhiteSur theme
if [ ! -d "$HOME/WhiteSur-gtk-theme" ]; then
  git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git $HOME/WhiteSur-gtk-theme
fi
cd $HOME/WhiteSur-gtk-theme
./install.sh --icon --cursor

# Apply WhiteSur theme
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur"

# Run XFCE4 Desktop
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

exit 0
