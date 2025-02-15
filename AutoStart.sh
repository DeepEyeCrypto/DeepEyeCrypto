#!/bin/bash

# Check if DeepEyeCrypto.sh exists
if [ ! -f ~/DeepEyeCrypto.sh ]; then
    echo "Error: DeepEyeCrypto.sh not found in home directory. Place the file in ~/ and rerun this script."
    exit 1
fi

# Ensure DeepEyeCrypto.sh is executable
chmod +x ~/DeepEyeCrypto.sh

# Add command to .bashrc if not already present
if ! grep -qF "bash ~/DeepEyeCrypto.sh" ~/.bashrc; then
    echo "bash ~/DeepEyeCrypto.sh" >> ~/.bashrc
    echo "Command added to ~/.bashrc. Restart Termux to see changes."
else
    echo "Command already exists in ~/.bashrc. No changes needed."
fi
