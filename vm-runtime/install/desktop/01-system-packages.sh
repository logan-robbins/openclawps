#!/usr/bin/env bash
# 01-system-packages.sh -- base desktop packages for the claw-os bake on the
# AMD V710 marketplace image.
#
# Marketplace base already provides: kernel pin, amdgpu driver, ROCm/AMF userspace.
# This script intentionally does NOT do `apt-get upgrade` (would pull a newer
# kernel the vendor driver doesn't build against).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update

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
  xserver-xorg-video-dummy \
  tmux \
  curl \
  wget \
  ca-certificates \
  gnupg \
  jq \
  git \
  net-tools \
  pciutils

# render/video groups for GPU/uinput access (Sunshine input injection
# + ROCm /dev/kfd on the V710 — without render, processes see the amdgpu
# node but get "Unable to open /dev/kfd read-write: Permission denied").
groupadd -f render
groupadd -f video
if id azureuser >/dev/null 2>&1; then
  usermod -aG render,video azureuser
fi

# Purge light-locker (10-min lock trap over remote desktop)
apt-get purge -y light-locker light-locker-settings 2>/dev/null || true

# Azure NSG is the only enforcement boundary — disable host firewall
systemctl stop ufw || true
systemctl disable ufw || true
ufw --force disable || true
