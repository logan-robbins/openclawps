#!/usr/bin/env bash
# 010-sunshine-config.sh -- bring existing VMs in line with the corrected
# Sunshine install (05-sunshine.sh). Three problems this patches on already-
# deployed claws:
#
#   1. Sunshine's default capture probe picks KMS on the hyperv_drm card,
#      which renders an empty framebuffer → Moonlight shows a black screen.
#      Fix: write `capture = x11` so it attaches to the XFCE :0 session.
#
#   2. Sunshine's unit is missing XDG_RUNTIME_DIR, so it can't find the user
#      PulseAudio socket → "Couldn't connect to pulseaudio: Access denied".
#      Fix: ensure XDG_RUNTIME_DIR + pulse-access/audio group membership.
#
#   3. Every fresh VM lands in the /welcome first-run state, forcing a manual
#      POST /api/password before Moonlight can be paired.
#      Fix: seed admin credentials from /mnt/claw-data/vnc-password.txt so the
#      Sunshine web UI login matches the VNC / VM password.
#
# Idempotent: safe to rerun. Runs as root under run-updates.sh.
set -euo pipefail

ADMIN_USER="azureuser"
ADMIN_HOME="/home/${ADMIN_USER}"
CONF_DIR="${ADMIN_HOME}/.config/sunshine"
CONF="${CONF_DIR}/sunshine.conf"
STATE="${CONF_DIR}/sunshine_state.json"
UNIT="/etc/systemd/system/sunshine.service"
VNC_PASS_FILE="/mnt/claw-data/vnc-password.txt"

# ---------------------------------------------------------------------------
# 1. Ensure capture = x11 in the per-VM sunshine.conf
# ---------------------------------------------------------------------------
install -d -o "$ADMIN_USER" -g "$ADMIN_USER" -m 0700 "$CONF_DIR"
if [[ ! -f "$CONF" ]]; then
    install -o "$ADMIN_USER" -g "$ADMIN_USER" -m 0644 /dev/null "$CONF"
fi
if ! grep -qE '^[[:space:]]*capture[[:space:]]*=' "$CONF"; then
    echo "capture = x11" >> "$CONF"
    echo "[update-010] added capture = x11 to $CONF"
fi

# ---------------------------------------------------------------------------
# 2. Audio access — XDG_RUNTIME_DIR in the unit + pulse-access/audio groups
# ---------------------------------------------------------------------------
unit_changed=0
if [[ -f "$UNIT" ]] && ! grep -q '^Environment=XDG_RUNTIME_DIR=' "$UNIT"; then
    uid=$(id -u "$ADMIN_USER")
    sed -i "/^Environment=XAUTHORITY=/a Environment=XDG_RUNTIME_DIR=/run/user/${uid}" "$UNIT"
    unit_changed=1
    echo "[update-010] added XDG_RUNTIME_DIR to $UNIT"
fi

for grp in pulse-access audio; do
    if getent group "$grp" >/dev/null && ! id -nG "$ADMIN_USER" | tr ' ' '\n' | grep -qx "$grp"; then
        usermod -aG "$grp" "$ADMIN_USER"
        echo "[update-010] added $ADMIN_USER to $grp"
    fi
done

if (( unit_changed )); then
    systemctl daemon-reload
fi

# ---------------------------------------------------------------------------
# 3. Seed admin credentials on first run
# ---------------------------------------------------------------------------
seed_admin() {
    if [[ -f "$STATE" ]]; then
        echo "[update-010] sunshine admin already seeded"
        return 0
    fi
    if [[ ! -f "$VNC_PASS_FILE" ]]; then
        echo "[update-010] $VNC_PASS_FILE not present yet — skipping admin seed"
        return 0
    fi

    local vnc_pass
    vnc_pass=$(tr -d '\r\n' < "$VNC_PASS_FILE")
    if [[ -z "$vnc_pass" ]]; then
        echo "[update-010] empty VNC password — skipping admin seed"
        return 0
    fi

    systemctl is-active --quiet sunshine || systemctl start sunshine
    for _ in {1..30}; do
        ss -tln 2>/dev/null | grep -q ':47990 ' && break
        sleep 1
    done

    local body resp
    body=$(jq -cn --arg u "$ADMIN_USER" --arg p "$vnc_pass" \
        '{currentUsername:"",currentPassword:"",newUsername:$u,newPassword:$p,confirmNewPassword:$p}')
    resp=$(curl -sk --max-time 10 -X POST https://127.0.0.1:47990/api/password \
        -H 'Content-Type: application/json' --data "$body" || true)

    if [[ "$resp" == *'"status":true'* ]]; then
        echo "[update-010] sunshine admin seeded (user=$ADMIN_USER, password=VNC password)"
        systemctl restart sunshine
    else
        echo "[update-010] admin seed response: ${resp:-<empty>}"
    fi
}

# Apply the config change by restarting sunshine (if it's running and we
# actually changed something). Seed admin afterwards.
if (( unit_changed )) && systemctl is-active --quiet sunshine; then
    systemctl restart sunshine
fi
seed_admin
