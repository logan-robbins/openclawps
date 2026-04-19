#!/usr/bin/env bash
# 05-sunshine.sh -- LizardByte Sunshine for low-latency H.264/HEVC streaming over Moonlight clients
# AMD VAAPI hardware encode via the Radeon Pro V710 amdgpu driver
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Resolve latest Sunshine release tag dynamically (avoids hardcoded 404s)
# and grab the .deb for the running Ubuntu version.
UBU_VER=$(. /etc/os-release; echo "$VERSION_ID")
LATEST_TAG=$(curl -sI https://github.com/LizardByte/Sunshine/releases/latest \
  | awk -F'/' '/^location:/ {print $NF}' | tr -d '\r\n')
if [[ -z "$LATEST_TAG" ]]; then
  echo "ERROR: could not resolve latest Sunshine release tag" >&2
  exit 1
fi
SUNSHINE_URL="https://github.com/LizardByte/Sunshine/releases/download/${LATEST_TAG}/sunshine-ubuntu-${UBU_VER}-amd64.deb"
echo "Installing Sunshine ${LATEST_TAG} for Ubuntu ${UBU_VER}"

wget -O /tmp/sunshine.deb "$SUNSHINE_URL"
apt-get install -y /tmp/sunshine.deb
rm -f /tmp/sunshine.deb

# Default config baked into the image. Per-VM config lives at
# ~/.config/sunshine/sunshine.conf and is seeded from this file on first start
# by ExecStartPre below. `capture = x11` is mandatory: the default auto-probe
# picks KMS on the hyperv_drm card (card1), which renders an empty framebuffer
# while the real XFCE session is on amdgpu (card0) — resulting in a black stream.
install -d -m 0755 /etc/sunshine
cat > /etc/sunshine/default.conf <<'CONF'
capture = x11
CONF

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
# PulseAudio runs in the azureuser session; without XDG_RUNTIME_DIR sunshine
# can't find /run/user/1000/pulse/native → "Couldn't connect to pulseaudio".
Environment=XDG_RUNTIME_DIR=/run/user/1000
# Seed per-VM sunshine.conf from the baked default if the user has none.
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X0 ]; do sleep 1; done'
ExecStartPre=/bin/bash -c 'install -d -o azureuser -g azureuser -m 0700 /home/azureuser/.config/sunshine && [ -f /home/azureuser/.config/sunshine/sunshine.conf ] || install -o azureuser -g azureuser -m 0644 /etc/sunshine/default.conf /home/azureuser/.config/sunshine/sunshine.conf'
ExecStart=/usr/bin/sunshine
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# Let azureuser reach the PulseAudio socket for streamed audio.
usermod -aG pulse-access,audio azureuser || true

# Sunshine needs CAP_SYS_ADMIN for input injection (uinput) — grant via udev
cat > /etc/udev/rules.d/85-sunshine-input.rules <<'UDEV'
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"
UDEV

systemctl daemon-reload
systemctl enable sunshine.service

# Sunshine listens on:
#   47984/tcp  HTTPS (web UI + pairing)
#   47989/tcp  HTTP (legacy)
#   47990/tcp  HTTPS (web UI alt)
#   48010/tcp  RTSP
#   47998-48000/udp  video/audio/control
