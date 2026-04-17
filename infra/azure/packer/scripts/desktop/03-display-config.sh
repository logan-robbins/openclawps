#!/usr/bin/env bash
# 03-display-config.sh -- LightDM autologin into XFCE on :0
# (BusID-specific xorg Device section is written at first boot, not bake time)
set -euo pipefail

mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf <<'CONF'
[Seat:*]
autologin-user=azureuser
autologin-user-timeout=0
user-session=xfce
CONF

# Disable XFCE screen blanking / DPMS so a long-idle desktop stays alive over remote
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/disable-blanking.desktop <<'DESK'
[Desktop Entry]
Type=Application
Name=Disable screen blanking and DPMS
Comment=Keep the :0 session awake forever for remote-desktop viewers
Exec=bash -c "xset s off s noblank -dpms"
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK
