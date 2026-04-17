#!/usr/bin/env bash
# 01-system-packages.sh -- base packages for the claw-desktop-gpu baseline image
# (XFCE + LightDM + tools; AMD driver / xrdp / Sunshine handled in later scripts)
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

# Pin kernel 6.5 (per MS Learn AMD V710 guide; 6.8 has known amdgpu issues)
apt-get install -y linux-image-6.5.0-1025-azure linux-headers-6.5.0-1025-azure linux-modules-6.5.0-1025-azure
apt-get install -y linux-headers-azure
sed -i 's|^GRUB_DEFAULT=.*|GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.5.0-1025-azure"|' /etc/default/grub
update-grub

apt-get install -y \
  xfce4 \
  xfce4-session \
  xfce4-goodies \
  lightdm \
  dbus-x11 \
  xdotool \
  wmctrl \
  scrot \
  xclip \
  x11-utils \
  xvfb \
  tmux \
  curl \
  wget \
  ca-certificates \
  gnupg \
  jq \
  git \
  build-essential \
  python3-setuptools \
  python3-wheel \
  net-tools \
  pciutils

# Add azureuser to video/render groups (required for amdgpu)
# (azureuser is created by cloud-init, but the groups must already exist)
groupadd -f render
groupadd -f video

# Purge light-locker (causes 10-min screen lock trap over remote desktop)
apt-get purge -y light-locker light-locker-settings 2>/dev/null || true

# Disable host-side firewall (Azure NSG is the only enforcement boundary)
systemctl stop ufw || true
systemctl disable ufw || true
ufw --force disable || true
