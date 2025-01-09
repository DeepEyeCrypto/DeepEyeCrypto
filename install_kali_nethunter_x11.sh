#!/bin/bash

# Update and install required packages
echo "Updating Termux packages..."
pkg update -y && pkg upgrade -y
pkg install -y proot wget tar termux-x11

# Variables
UBUNTU_VERSION="22.04"  # Change version if needed
ROOTFS_URL="https://partner-images.canonical.com/core/${UBUNTU_VERSION}/current/ubuntu-${UBUNTU_VERSION}-core-arm64-root.tar.gz"
INSTALL_DIR="$HOME/ubuntu"

# Create installation directory
echo "Setting up installation directory..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Download Ubuntu root filesystem
echo "Downloading Ubuntu $UBUNTU_VERSION root filesystem..."
wget -q --show-progress $ROOTFS_URL -O ubuntu-rootfs.tar.gz

# Extract root filesystem
echo "Extracting root filesystem..."
proot --link2symlink tar -xzf ubuntu-rootfs.tar.gz --directory=$INSTALL_DIR
rm ubuntu-rootfs.tar.gz

# Create launch script
echo "Creating launch script..."
cat > start-ubuntu.sh << EOF
#!/bin/bash
proot --link2symlink -0 -r $INSTALL_DIR -b /dev -b /proc -b /sys -b /data/data/com.termux/files/home -b /data/data/com.termux/files/usr/tmp:/tmp /usr/bin/env -i HOME=/root TERM="\$TERM" PS1='[ubuntu@termux]# ' PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash --login
EOF

chmod +x start-ubuntu.sh

# Install desktop environment and X11
echo "Setting up Ubuntu Desktop Environment..."
bash start-ubuntu.sh << EOF
apt update -y && apt upgrade -y
apt install -y xfce4 xfce4-goodies x11-utils dbus-x11
exit
EOF

# Setup Termux X11 Server
echo "Setting up Termux X11 server..."
pkg install -y termux-x11
echo "export DISPLAY=:0" >> ~/.bashrc
source ~/.bashrc

# Inform the user
echo "Installation complete!"
echo "To start Ubuntu, run: ./start-ubuntu.sh"
echo "To launch the graphical environment, use a VNC viewer or Termux-X11."
