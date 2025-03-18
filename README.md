# 🖥️ One-Click XFCE Desktop X11 for Termux
![Mac OS theme](Screenshot_20250108-205306.png)
### 🚀 **Easily set up and launch an XFCE desktop environment with X11 on Termux in one command!**

This script automates the installation of **XFCE desktop**, **X11 server**, **PulseAudio**, and a **macOS-inspired theme**, providing a ready-to-use desktop environment on your Android device.

---

## 📦 **Features**

- ✅ **Automated Setup:** Installs XFCE, X11 server, and PulseAudio.
- 🎨 **macOS Theme:** Applies WhiteSur GTK and icon themes.
- 🛠️ **Alias Support:** Quick launch with a single command.
- 📊 **Lightweight:** Optimized for Android's limited resources.
# Prerequisites
# **universal.apk**
- Install [Termux](https://termux.dev/) on your Android device.
- Install [Termux-X11](https://github.com/termux/termux-x11) for graphical support.
---

# **1. basic xfce desktop**
```bash
curl -sL https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/setup.sh | bash
./setup.sh

```
# ** START**

```bash
bash ~/DeepEyeCrypto.sh
```
# **2. powerful desktop**
```bash
pkg install wget
wget https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/termux-ultimate-setup.sh
chmod +x termux-ultimate-setup.sh
./termux-ultimate-setup.sh
```
# ** START**

```bash
tx11start --legacy
```
# **1. advance desktop**
```bash
curl -sL https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/setup.sh | bash
./setup.sh
```
# **2. install Theme**
```bash
cd ~
wget https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/Mac-theme.sh
chmod +x Mac-theme.sh
./Mac-theme.sh

```
## Troubleshooting

### Process Completed (Signal 9) - Press Enter

1. Install LADB from the Play Store or download it from [here](https://github.com/hyperio546/ladb-builds/releases).
2. Connect to Wi-Fi.
3. Enable wireless debugging in Developer Settings and note the port number and pairing code.
4. Enter these values in LADB.
5. Once connected, run the following command:

```bash
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```

You can also run `adb shell` directly from Termux by following the guide in this video:  
[YouTube Guide](https://www.youtube.com/watch?v=BHc7uvX34bM)
