#!/usr/bin/env bash
# 012-gateway-env-path.sh -- fix the openclaw-gateway service to read the
# actual location of the per-claw .env (under ~/.openclaw/, not ~/).
#
# In images <= claw-os v1.0.0 the unit file had:
#   EnvironmentFile=/home/azureuser/.env
#   ConditionPathExists=/home/azureuser/.env
# but cloud-init writes the secrets to /home/azureuser/.openclaw/.env
# (which is the bind-mounted view of /mnt/claw-data/openclaw/.env).
# The wrong path meant the gateway could never start.
#
# This migration rewrites the unit file in place and reloads systemd.
# Idempotent: sed -i is a no-op if the correct path is already present.

set -euo pipefail

UNIT_FILE="/etc/systemd/system/openclaw-gateway.service"

if [[ ! -f "$UNIT_FILE" ]]; then
    echo "[update-012] $UNIT_FILE does not exist; nothing to migrate"
    exit 0
fi

CHANGED=0

if grep -q '^EnvironmentFile=/home/azureuser/\.env$' "$UNIT_FILE"; then
    sed -i 's|^EnvironmentFile=/home/azureuser/\.env$|EnvironmentFile=/home/azureuser/.openclaw/.env|' "$UNIT_FILE"
    CHANGED=1
fi

if grep -q '^ConditionPathExists=/home/azureuser/\.env$' "$UNIT_FILE"; then
    sed -i 's|^ConditionPathExists=/home/azureuser/\.env$|ConditionPathExists=/home/azureuser/.openclaw/.env|' "$UNIT_FILE"
    CHANGED=1
fi

if (( CHANGED == 1 )); then
    systemctl daemon-reload
    systemctl restart openclaw-gateway 2>/dev/null || true
    echo "[update-012] Rewrote openclaw-gateway EnvironmentFile/ConditionPathExists to ~/.openclaw/.env"
else
    echo "[update-012] openclaw-gateway already uses the correct .env path"
fi
