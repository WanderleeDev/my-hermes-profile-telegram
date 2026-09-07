#!/bin/bash
# Setup SSH Monitor Service for telegram-bot profile
# Usage: ./scripts/setup-ssh-monitor.sh

PROFILE_PATH="/home/ubuntu/.hermes/profiles/telegram-bot"
SERVICE_SOURCE="$PROFILE_PATH/systemd/ssh-monitor.service"
SERVICE_DEST="$HOME/.config/systemd/user/ssh-monitor.service"

echo "Setting up SSH Monitor service..."

# Check if scripts exist
if [ ! -f "$PROFILE_PATH/scripts/ssh-monitor.sh" ]; then
    echo "ERROR: ssh-monitor.sh not found at $PROFILE_PATH/scripts/"
    exit 1
fi

if [ ! -f "$PROFILE_PATH/scripts/ssh-alert.sh" ]; then
    echo "ERROR: ssh-alert.sh not found at $PROFILE_PATH/scripts/"
    exit 1
fi

# Copy service file
cp "$SERVICE_SOURCE" "$SERVICE_DEST"
echo "Service file installed to $SERVICE_DEST"

# Reload systemd
systemctl --user daemon-reload
echo "Systemd daemon reloaded"

# Enable and start service
systemctl --user enable ssh-monitor.service
systemctl --user start ssh-monitor.service

# Check status
sleep 2
systemctl --user status ssh-monitor.service --no-pager

echo ""
echo "SSH Monitor setup complete!"
echo "Monitor script: $PROFILE_PATH/scripts/ssh-monitor.sh"
echo "Alert script:   $PROFILE_PATH/scripts/ssh-alert.sh"
echo "Service status: systemctl --user status ssh-monitor.service"
