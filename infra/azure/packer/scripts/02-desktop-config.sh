#!/usr/bin/env bash
# 02-desktop-config.sh -- configure lightdm, xorg, x11vnc, and openclaw-gateway
set -euo pipefail

# ---- lightdm auto-login into xfce on :0 ----
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf <<'CONF'
[Seat:*]
autologin-user=azureuser
autologin-user-timeout=0
user-session=xfce
CONF

# ---- Dummy Xorg driver (stable headless desktop on Azure) ----
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/99-dummy.conf <<'XORG'
Section "Device"
    Identifier "dummy_vga"
    Driver "dummy"
    VideoRam 256000
EndSection
Section "Screen"
    Identifier "dummy_screen"
    Device "dummy_vga"
    Monitor "dummy_monitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080" "1280x1024" "1024x768"
    EndSubSection
EndSection
Section "Monitor"
    Identifier "dummy_monitor"
    HorizSync   1-200
    VertRefresh 1-200
EndSection
XORG

# ---- Disable xfce screen blanking/DPMS ----
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/disable-blanking.desktop <<'DESK'
[Desktop Entry]
Type=Application
Name=Disable screen blanking and DPMS
Comment=Keep the :0 session awake forever so VNC viewers always see live content
Exec=bash -c "xset s off s noblank -dpms"
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK

# ---- x11vnc systemd unit ----
cat > /etc/systemd/system/x11vnc.service <<'UNIT'
[Unit]
Description=x11vnc server attached to the lightdm autologin :0 session (view-only)
After=lightdm.service
Wants=lightdm.service

[Service]
Type=simple
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X0 ]; do sleep 1; done'
ExecStart=/usr/bin/x11vnc \
    -display :0 \
    -auth guess \
    -rfbport 5900 \
    -rfbauth /etc/x11vnc.pass \
    -forever \
    -shared \
    -viewonly \
    -noxdamage \
    -o /var/log/x11vnc.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# ---- OpenClaw gateway systemd unit ----
cat > /etc/systemd/system/openclaw-gateway.service <<'UNIT'
[Unit]
Description=OpenClaw Gateway (auto-starts at boot, binds to Telegram)
After=network-online.target lightdm.service x11vnc.service
Wants=network-online.target lightdm.service x11vnc.service
ConditionPathExists=/home/azureuser/.openclaw/openclaw.json
ConditionPathExists=/home/azureuser/.env

[Service]
Type=simple
User=azureuser
Group=azureuser
WorkingDirectory=/home/azureuser
Environment=HOME=/home/azureuser
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/azureuser/.Xauthority
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
Environment=OPENCLAW_NO_RESPAWN=1
EnvironmentFile=/home/azureuser/.env
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X0 ]; do sleep 1; done'
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
