#!/data/data/com.termux/files/usr/bin/bash

# ============================
# XFCE4 Termux-X11 Setup Script
# ============================

# Kill existing X11 and PulseAudio processes
echo "[*] Stopping existing X11 and PulseAudio processes..."
pkill -f "termux.x11" 2>/dev/null
pkill -f "pulseaudio" 2>/dev/null

# ============================
# Start PulseAudio with TCP Support
# ============================
echo "[*] Starting PulseAudio..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
if [ $? -ne 0 ]; then
    echo "[!] Failed to start PulseAudio."
    exit 1
fi

# Set PulseAudio server
export PULSE_SERVER=127.0.0.1

# ============================
# Start Termux-X11 Display Server
# ============================
echo "[*] Starting Termux-X11 Display Server..."
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null 2>&1 &
sleep 3

# Verify Termux-X11 started successfully
if ! pgrep -f "termux.x11" > /dev/null; then
    echo "[!] Failed to start Termux-X11 display server."
    exit 1
fi

# Launch Termux-X11 MainActivity
echo "[*] Launching Termux-X11 MainActivity..."
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] Failed to launch Termux-X11 MainActivity."
    exit 1
fi
sleep 1

# ============================
# Start XFCE4 Desktop Session
# ============================
echo "[*] Starting XFCE4 Desktop Session..."
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session > /dev/null 2>&1 &
if [ $? -ne 0 ]; then
    echo "[!] Failed to start XFCE4 session."
    exit 1
fi

# ============================
# Final Confirmation
# ============================
echo "[✔] XFCE4 Desktop is now running on Termux-X11 with PulseAudio enabled."
echo "[*] Access the graphical desktop via Termux-X11."

exit 0
