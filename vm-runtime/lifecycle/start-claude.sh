#!/usr/bin/env bash
# /opt/claw/start-claude.sh -- launch Claude Code remote-control in a tmux session
#
# Idempotent: if the "claude" tmux session already exists, does nothing.
# Should be run as azureuser (boot.sh calls it via sudo -u azureuser).

set -euo pipefail

cd ~/workspace 2>/dev/null || cd ~

if ! tmux has-session -t claude 2>/dev/null; then
    tmux new-session -d -s claude "claude remote-control --name '$(hostname)'"
    echo "[start-claude] Started claude remote-control in tmux session 'claude'"
else
    echo "[start-claude] tmux session 'claude' already exists -- skipping"
fi
