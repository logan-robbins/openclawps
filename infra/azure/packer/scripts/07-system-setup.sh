#!/usr/bin/env bash
# 07-system-setup.sh -- sudoers, directory structure, enable services
set -euo pipefail

# Passwordless sudo for azureuser (full agent autonomy)
echo "azureuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/azureuser-full
chmod 440 /etc/sudoers.d/azureuser-full

# /opt/claw directory structure (boot files staged here by Packer provisioners)
mkdir -p /opt/claw/defaults /opt/claw/updates

# Home directory structure
mkdir -p /home/azureuser/workspace /home/azureuser/.openclaw
chown -R azureuser:azureuser /home/azureuser

# xfce session hint
sudo -u azureuser bash -c 'echo xfce4-session > ~/.xsession && chmod 644 ~/.xsession'

# Enable graphical target + services
systemctl set-default graphical.target
systemctl enable lightdm
systemctl enable x11vnc
systemctl enable openclaw-gateway
