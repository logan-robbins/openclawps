#!/usr/bin/env bash
# 03-display-config.sh -- LightDM autologin into XFCE on :0 + dummy Xorg config
#
# The AMD Radeon Pro V710 in Azure NV*ads_V710_v5 SKUs runs in MxGPU compute
# partition mode — it cannot drive an Xorg display directly. Xorg with no
# explicit driver falls through to the Hyper-V virtual VGA (PCI 1414:0006),
# for which no driver exists, and crash-loops with "no screens found".
#
# Solution: dummy driver provides a virtual 1920x1080 framebuffer for Xorg /
# XFCE / xrdp. Sunshine uses VAAPI (libva + radeonsi) to do real H.264/HEVC/
# AV1 hardware encode on the V710 — VAAPI is independent of which driver
# runs the X server, so we keep GPU acceleration where it matters.
set -euo pipefail

mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf <<'CONF'
[Seat:*]
autologin-user=azureuser
autologin-user-timeout=0
user-session=xfce
CONF

# Dummy Xorg device (Xorg on :0 needs *some* device; the AMD GPU isn't usable
# as a display device in MxGPU mode).
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/99-dummy.conf <<'XORG'
Section "Device"
    Identifier "dummy_vga"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "dummy_monitor"
    HorizSync   1-200
    VertRefresh 1-200
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

Section "ServerLayout"
    Identifier "dummy_layout"
    Screen "dummy_screen"
EndSection
XORG

# Disable XFCE screen blanking / DPMS so an idle desktop stays alive over remote
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
