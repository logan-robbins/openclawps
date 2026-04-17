#!/usr/bin/env bash
# 04-xrdp.sh -- xrdp with H.264 GFX pipeline, attached to LightDM XFCE on :0
# Per-user xrdp launches a fresh X session by default; we want the existing
# autologin :0 so the human sees the persistent desktop, not a transient one.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get install -y xrdp xorgxrdp

# xrdp must run as the xrdp user but needs to read the X authority of :0
usermod -aG ssl-cert xrdp

# Configure xrdp to attach to existing :0 (not spawn a new Xvnc/Xorg per session)
# This requires xrdp's "session manager" to know about display :0.
cat > /etc/xrdp/startwm.sh <<'WM'
#!/bin/sh
# Use the running :0 session if available; else start a fresh xfce session.
if [ -e /tmp/.X11-unix/X0 ]; then
  # Attach to existing display
  exec env DISPLAY=:0 dbus-launch --exit-with-session true
fi
. /etc/X11/Xsession
WM
chmod +x /etc/xrdp/startwm.sh

# Force xrdp to prefer the H.264 GFX pipeline (smoother, lower bandwidth than 0.9 RemoteFX)
sed -i 's|^use_compression=.*|use_compression=true|' /etc/xrdp/xrdp.ini || true
sed -i 's|^max_bpp=.*|max_bpp=32|' /etc/xrdp/xrdp.ini || true
# Enable H.264 codec mode
sed -i 's|^new_cursors=.*|new_cursors=true|' /etc/xrdp/xrdp.ini || true
if ! grep -q '^\[Xorg\]' /etc/xrdp/sesman.ini; then
  echo "" >> /etc/xrdp/sesman.ini
fi

# Allow X server connections from xrdp user
cat > /etc/X11/Xwrapper.config <<'XW'
allowed_users=anybody
needs_root_rights=yes
XW

# xrdp listens on 3389 by default; LightDM autologin and xfce already configured by 03
