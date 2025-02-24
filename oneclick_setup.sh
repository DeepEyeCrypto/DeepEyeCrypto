#!/bin/bash

# Create the update script
cat > ~/update_automation.sh << 'EOF'
#!/bin/bash

# Update and upgrade with logging
echo "[$(date)] Starting system update..." >> ~/update.log
pkg update -y && pkg upgrade -y >> ~/update.log 2>&1
echo "[$(date)] Update completed" >> ~/update.log
EOF

# Make executable
chmod +x ~/update_automation.sh

# Install cron if needed
pkg install cronie -y > /dev/null 2>&1

# Setup cron job
(crontab -l 2>/dev/null; echo "0 */12 * * * /data/data/com.termux/files/home/update_automation.sh") | crontab -

# Enable cron service
sv-enable crond

echo "Automatic updates configured successfully!"
echo "Updates will run every 12 hours (12AM/12PM)"
echo "Logs can be viewed with: cat ~/update.log"
