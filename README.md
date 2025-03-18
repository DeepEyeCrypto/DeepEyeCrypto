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
## Getting Started:

##### 1. Ensure Requirements Are Met:
   - Android 8+ device
   - **[Termux](https://termux.dev/en/)** (download from [GitHub](https://github.com/termux/termux-app/releases) or [F-Droid](https://f-droid.org/en/packages/com.termux/))
      >NOTE: This Only Works On Termux From Github Or Fdroid

     > Avoid using Termux from Google Play due to API limitations.
   - **[Termux:X11](https://github.com/termux/termux-x11/releases)**
   - **[Termux-API](https://github.com/termux/termux-api/releases)**
   - Minimum 2GB of RAM (3GB recommended)
   - 1.5-2GB of Internet data
   - 3-4GB of free storage
##### 2. Explore Desktop Styles this for powerful desktop:
   - **[XFCE](xfce_styles.md)**
   - **[LXQt](lxqt_styles.md)**
   - **[OPENBOX](openbox_styles.md)**
   - **[MATE](mate_styles.md)**
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
# **3. advance desktop**
```bash
curl -sL https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/xfce-desktop.sh | bash
```
## Starting the Desktop

To start the desktop, use the following command:

```bash
start
```

This command initiates a Termux-X11 session, starts the XFCE4 desktop, and opens the Termux-X11 app directly into the desktop.

To access the Debian proot environment from the terminal, use:

```bash
debian
```

Note: The display is pre-configured in the Debian proot environment, allowing you to launch GUI applications directly from the terminal.

# **2. install Theme**
```bash
cd ~
wget https://github.com/DeepEyeCrypto/DeepEyeCrypto/raw/refs/heads/main/themes.sh
chmod +x themes.sh
./themes.sh

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
