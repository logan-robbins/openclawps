#!/usr/bin/env bash
# 05-sunshine.sh -- LizardByte Sunshine for low-latency H.264/HEVC streaming over Moonlight clients
# AMD VAAPI hardware encode via the Radeon Pro V710 amdgpu driver
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Sunshine .deb for Ubuntu 24.04 (latest stable)
SUNSHINE_VERSION="2025.118.155747"
SUNSHINE_URL="https://github.com/LizardByte/Sunshine/releases/download/v${SUNSHINE_VERSION}/sunshine-ubuntu-24.04-amd64.deb"

wget -q -O /tmp/sunshine.deb "$SUNSHINE_URL"
apt-get install -y /tmp/sunshine.deb
rm -f /tmp/sunshine.deb

# System-wide systemd unit attached to the LightDM autologin :0 session.
# Sunshine ships a user-mode unit by default; we want a system unit so it starts
# at boot regardless of who is logged in.
cat > /etc/systemd/system/sunshine.service <<'UNIT'
[Unit]
Description=Sunshine self-hosted game stream host (attached to LightDM :0 session)
After=lightdm.service network-online.target
Wants=lightdm.service network-online.target

[Service]
Type=simple
User=azureuser
Group=azureuser
Environment=HOME=/home/azureuser
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/azureuser/.Xauthority
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X0 ]; do sleep 1; done'
ExecStart=/usr/bin/sunshine
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# Sunshine needs CAP_SYS_ADMIN for input injection (uinput) — grant via udev
cat > /etc/udev/rules.d/85-sunshine-input.rules <<'UDEV'
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"
UDEV

# Sunshine listens on:
#   47984/tcp  HTTPS (web UI + pairing)
#   47989/tcp  HTTP (legacy)
#   47990/tcp  HTTPS (web UI alt)
#   48010/tcp  RTSP
#   47998-48000/udp  video/audio/control
