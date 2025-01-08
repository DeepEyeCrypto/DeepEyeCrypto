# One-click-xfce-desktop-X11

# 🖥️ One-Click XFCE Desktop X11 for Termux
git add README.md
git commit -m "Screenshot_20250108-205306.png"
git push origin main
### 🚀 **Easily set up and launch an XFCE desktop environment with X11 on Termux in one command!**

This script automates the installation of **XFCE desktop**, **X11 server**, **PulseAudio**, and a **macOS-inspired theme**, providing a ready-to-use desktop environment on your Android device.

---

## 📦 **Features**

- ✅ **Automated Setup:** Installs XFCE, X11 server, and PulseAudio.
- 🎨 **macOS Theme:** Applies WhiteSur GTK and icon themes.
- 🛠️ **Alias Support:** Quick launch with a single command.
- 📊 **Lightweight:** Optimized for Android's limited resources.

---

# **1. Clone the Repository**
```bash
pkg update -y && pkg upgrade -y
pkg install git -y
git clone https://github.com/DeepEyeCrypto/DeepEyeCrypto.git
cd DeepEyeCrypto
chmod +x xfce-macos-setup.sh
./xfce-macos-setup.sh

```
# **Launch XFCE Desktop
Open the Termux X11 App, then run:

```bash
xfce
```
---

# **2. TROUBLESHOOTING.md**

# 🐞 **Troubleshooting Guide**

This guide will help you resolve common issues while setting up **XFCE Desktop with X11 on Termux**.

---

# ⚠️ **3. Display Server Issues**

**Problem:** XFCE fails to start or shows a blank screen.  

**Solution:**  
1. Ensure **Termux X11 App** is installed.  
2. Restart X11 Server manually:
```bash
termux-x11 :1 &
export DISPLAY=:1
startxfce4

```
