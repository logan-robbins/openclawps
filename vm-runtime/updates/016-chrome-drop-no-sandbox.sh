#!/usr/bin/env bash
# 016-chrome-drop-no-sandbox.sh -- remove --no-sandbox from Chrome launches.
#
# Chrome was previously launched with --no-sandbox everywhere, which
# triggers a yellow warning bar in every new window ("You are using an
# unsupported command-line flag: --no-sandbox. Stability and security
# will suffer.") and genuinely degrades renderer isolation.
#
# The flag is unnecessary on this VM:
#   - /opt/google/chrome/chrome-sandbox is installed SUID root (4755).
#   - kernel.unprivileged_userns_clone=1 and AppArmor's 'chrome'
#     profile (shipped by the google-chrome package) grants the
#     userns capability needed for the namespace sandbox.
#   - Live chrome processes already run under the 'chrome' AppArmor
#     profile, confirming the sandbox works here.
#
# Fixes three places:
#   1. Live /mnt/claw-data/openclaw/openclaw.json  browser.noSandbox -> false
#   2. /home/azureuser/Desktop/Chrome.desktop      drop --no-sandbox from Exec
#   3. (Defaults JSON was already updated in the repo for fresh deploys.)
#
# Restart the gateway so the browser plugin reloads the new config.
# Idempotent: sed patterns don't match after the first application.
set -euo pipefail

# 1. Strip --no-sandbox from the XFCE desktop icon launcher.
DESKTOP_ICON=/home/azureuser/Desktop/Chrome.desktop
if [[ -f "$DESKTOP_ICON" ]] && grep -q -- '--no-sandbox' "$DESKTOP_ICON"; then
    # Remove the flag plus any surrounding single space.
    sed -i.bak -E 's/ --no-sandbox//g; s/--no-sandbox //g; s/--no-sandbox//g' "$DESKTOP_ICON"
    echo "[update-016] removed --no-sandbox from $DESKTOP_ICON"
else
    echo "[update-016] $DESKTOP_ICON absent or already clean"
fi

# 2. Live openclaw.json: flip browser.noSandbox true -> false. Single
#    line match avoids touching other booleans. lcm.db / other paths
#    are not affected.
LIVE=/mnt/claw-data/openclaw/openclaw.json
if [[ -f "$LIVE" ]]; then
    if grep -q '"noSandbox": true' "$LIVE"; then
        sed -i.bak 's|"noSandbox": true|"noSandbox": false|' "$LIVE"
        chown azureuser:azureuser "$LIVE"
        echo "[update-016] set browser.noSandbox=false in $LIVE"
        # Reload gateway so the browser plugin picks up the new flag.
        if systemctl is-active --quiet openclaw-gateway 2>/dev/null; then
            systemctl restart openclaw-gateway
            echo "[update-016] restarted openclaw-gateway"
        fi
    else
        echo "[update-016] $LIVE already has noSandbox=false (or absent)"
    fi
fi

# 3. If Chrome is running under --no-sandbox, kill so the next launch
#    (via the wrapper + clean .desktop) starts sandboxed. Agent respawns
#    Chrome on demand.
if pgrep -f 'google-chrome-stable.*--no-sandbox' >/dev/null 2>&1; then
    pkill -f 'google-chrome-stable.*--no-sandbox' || true
    echo "[update-016] killed stale --no-sandbox Chrome instances"
fi
