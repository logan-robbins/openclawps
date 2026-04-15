#!/usr/bin/env bash
# 07-system-setup.sh -- sudoers, directory structure, enable services
set -euo pipefail

# Passwordless sudo for azureuser (full agent autonomy)
echo "azureuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/azureuser-full
chmod 440 /etc/sudoers.d/azureuser-full

# /opt/claw directory structure (boot files staged here by Packer provisioners)
mkdir -p /opt/claw/defaults /opt/claw/updates

# Home directory and xfce session hint are handled by boot.sh at deploy time
# (azureuser doesn't exist during image build — cloud-init creates it)

# gh CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
apt-get update -qq
apt-get install -y gh

# codex CLI
npm install -g @openai/codex 2>/dev/null || true

# Enable graphical target + services
systemctl set-default graphical.target
systemctl enable lightdm
systemctl enable x11vnc
systemctl enable openclaw-gateway
