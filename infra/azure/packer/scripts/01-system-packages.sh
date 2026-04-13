#!/usr/bin/env bash
# 01-system-packages.sh -- install base system packages for claw VMs
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

apt-get install -y \
  xfce4 \
  xfce4-session \
  xfce4-goodies \
  lightdm \
  x11vnc \
  xserver-xorg-video-dummy \
  xdotool \
  wmctrl \
  scrot \
  xclip \
  x11-utils \
  tmux \
  curl \
  wget \
  ca-certificates \
  gnupg \
  jq \
  git \
  build-essential

# Purge light-locker (causes 10-min screen lock trap over VNC)
apt-get purge -y light-locker light-locker-settings 2>/dev/null || true

# Disable host-side firewall
systemctl stop ufw || true
systemctl disable ufw || true
ufw --force disable || true
