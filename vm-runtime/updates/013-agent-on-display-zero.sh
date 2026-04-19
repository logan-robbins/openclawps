#!/usr/bin/env bash
# 013-agent-on-display-zero.sh -- migrate the OpenClaw agent off its
# dedicated Xvfb :99 session and onto the shared XFCE :0 session.
#
# Problem this solves:
#   The agent's Chrome on :99 had its own user-data-dir lock, so the
#   human's Chrome on :0 (seen via Moonlight) couldn't share cookies,
#   GitHub auth, Google auth, or saved passwords with it. Logging into
#   GitHub through Moonlight did nothing for the agent.
#
#   Running both on :0 collapses them into one Chrome process with one
#   profile (~/.config/google-chrome), so auth state is naturally shared.
#   Moonlight captures :0, so the operator also SEES what the agent is
#   doing — both goals solved with one change.
#
# What this script does:
#   1. Disables + stops the old Xvfb :99 stack (xvfb, wm, observe units).
#   2. Rewrites /etc/systemd/system/openclaw-gateway.service to point at
#      DISPLAY=:0 with the LightDM-session Xauthority.
#   3. daemon-reloads and restarts the gateway.
#
# Idempotent: systemctl disable/stop are no-ops when the unit is already
# gone; the unit rewrite is a simple overwrite.
set -euo pipefail

UNIT_DIR=/etc/systemd/system

# 1. Retire the :99 stack. x11vnc as an observation path is also gone --
#    Moonlight on :0 replaces it.
for unit in openclaw-xvfb.service openclaw-wm.service openclaw-observe.service; do
    if systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -q "$unit"; then
        systemctl disable --now "$unit" 2>/dev/null || true
        rm -f "$UNIT_DIR/$unit"
        echo "[update-013] removed $unit"
    fi
done

# 2. Rewrite the gateway unit to target :0 + the lightdm XAUTHORITY.
cat > "$UNIT_DIR/openclaw-gateway.service" <<'UNIT'
[Unit]
Description=OpenClaw Gateway (runs on the shared XFCE :0 session)
After=graphical.target network-online.target
Wants=network-online.target graphical.target
ConditionPathExists=/home/azureuser/.openclaw/openclaw.json
ConditionPathExists=/home/azureuser/.openclaw/.env

[Service]
Type=simple
User=azureuser
Group=azureuser
WorkingDirectory=/home/azureuser
Environment=HOME=/home/azureuser
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/azureuser/.Xauthority
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
Environment=OPENCLAW_NO_RESPAWN=1
EnvironmentFile=/home/azureuser/.openclaw/.env
ExecStartPre=/bin/bash -c 'for _ in $(seq 1 120); do pgrep -u azureuser xfce4-session >/dev/null && exit 0; sleep 1; done; echo "timed out waiting for xfce4-session" >&2; exit 1'
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
UNIT
echo "[update-013] wrote openclaw-gateway.service targeting :0"

systemctl daemon-reload
systemctl enable openclaw-gateway.service >/dev/null

# 3. Stop any stale Xvfb :99 process left running outside the retired
#    unit (can happen if the service was removed before the X server
#    exited). Safe to run anytime -- pkill exits non-zero on no-match.
pkill -f 'Xvfb :99' 2>/dev/null || true

# 4. Restart the gateway so it picks up the new DISPLAY. The in-flight
#    task resumes from lcm.db per the normal restart contract.
systemctl restart openclaw-gateway.service
echo "[update-013] restarted openclaw-gateway on :0"
