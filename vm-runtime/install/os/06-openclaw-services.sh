#!/usr/bin/env bash
# 06-openclaw-services.sh -- systemd units that run OpenClaw on its own Xvfb display
# (independent of the human RDP session on :0 — survives connect/disconnect/restart)
set -euo pipefail

# ---- Xvfb on :99 (the agent's dedicated headless display) ----
cat > /etc/systemd/system/openclaw-xvfb.service <<'UNIT'
[Unit]
Description=Xvfb virtual X server on :99 for OpenClaw agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=azureuser
Group=azureuser
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension RANDR +extension RENDER -nolisten tcp
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

# ---- xfwm4 inside :99 so Chrome has a window manager (move/resize/focus) ----
cat > /etc/systemd/system/openclaw-wm.service <<'UNIT'
[Unit]
Description=xfwm4 window manager inside the OpenClaw Xvfb session (:99)
After=openclaw-xvfb.service
Requires=openclaw-xvfb.service

[Service]
Type=simple
User=azureuser
Group=azureuser
Environment=HOME=/home/azureuser
Environment=DISPLAY=:99
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X99 ]; do sleep 1; done'
ExecStart=/usr/bin/xfwm4 --display=:99 --replace
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

# ---- OpenClaw gateway bound to :99, decoupled from human RDP/Sunshine sessions ----
cat > /etc/systemd/system/openclaw-gateway.service <<'UNIT'
[Unit]
Description=OpenClaw Gateway (auto-starts at boot, runs on dedicated Xvfb :99)
After=openclaw-xvfb.service openclaw-wm.service network-online.target
Requires=openclaw-xvfb.service openclaw-wm.service
Wants=network-online.target
ConditionPathExists=/home/azureuser/.openclaw/openclaw.json
ConditionPathExists=/home/azureuser/.openclaw/.env

[Service]
Type=simple
User=azureuser
Group=azureuser
WorkingDirectory=/home/azureuser
Environment=HOME=/home/azureuser
Environment=DISPLAY=:99
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
Environment=OPENCLAW_NO_RESPAWN=1
EnvironmentFile=/home/azureuser/.openclaw/.env
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X99 ]; do sleep 1; done'
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

# ---- Optional: x11vnc bound only to :99 on port 5901, for observing the agent ----
# (separate from xrdp on 3389 which serves the human :0)
apt-get install -y x11vnc
cat > /etc/systemd/system/openclaw-observe.service <<'UNIT'
[Unit]
Description=x11vnc bound to OpenClaw Xvfb (:99) on port 5901 for agent observation
After=openclaw-xvfb.service
Requires=openclaw-xvfb.service

[Service]
Type=simple
User=azureuser
Group=azureuser
ExecStartPre=/bin/bash -c 'until [ -S /tmp/.X11-unix/X99 ]; do sleep 1; done'
ExecStart=/usr/bin/x11vnc -display :99 -rfbport 5901 -rfbauth /etc/x11vnc.pass -forever -shared -noxdamage
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
# (openclaw-observe is enabled separately if desired; not in 05-system-setup.sh by default)

systemctl daemon-reload

# Enable the new services so they start on boot. The gateway has
# ConditionPathExists guards on /home/azureuser/.openclaw/openclaw.json
# and /home/azureuser/.env so it stays inactive on a fresh image; the
# data-disk seed in /opt/claw/boot.sh provides those at first boot.
systemctl enable openclaw-xvfb.service
systemctl enable openclaw-wm.service
systemctl enable openclaw-gateway.service
