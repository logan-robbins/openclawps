#!/usr/bin/env bash
# /opt/claw/run-updates.sh -- apply pending update/migration scripts
#
# Reads the current version from /mnt/claw-data/update-version.txt (e.g. "001"),
# then runs every script in /opt/claw/updates/ whose number is greater than the
# current version, in order. Updates the version marker after each successful run.

set -euo pipefail

DATA_MOUNT="/mnt/claw-data"
UPDATES_DIR="/opt/claw/updates"
VERSION_FILE="${DATA_MOUNT}/update-version.txt"
LOG_TAG="claw-updates"

log() { echo "[${LOG_TAG}] $(date -u +%Y-%m-%dT%H:%M:%SZ) $*" | tee -a /var/log/claw-boot.log; }

if [[ ! -d "$UPDATES_DIR" ]]; then
    log "No updates directory at ${UPDATES_DIR} -- skipping"
    exit 0
fi

# Read current version (default 000 if no marker yet)
current_version="000"
if [[ -f "$VERSION_FILE" ]]; then
    current_version=$(cat "$VERSION_FILE" | tr -d '[:space:]')
fi
log "Current update version: ${current_version}"

# Find and run pending updates in order
pending=0
for script in "$UPDATES_DIR"/[0-9][0-9][0-9]-*.sh; do
    [[ -f "$script" ]] || continue
    basename_script=$(basename "$script")
    script_version="${basename_script%%-*}"

    if [[ "$script_version" > "$current_version" ]]; then
        log "Running update: ${basename_script}"
        if bash "$script"; then
            echo "$script_version" > "$VERSION_FILE"
            log "Update ${basename_script} completed -- version now ${script_version}"
            (( pending++ ))
        else
            log "ERROR: Update ${basename_script} failed -- stopping"
            exit 1
        fi
    fi
done

if (( pending == 0 )); then
    log "No pending updates"
else
    log "Applied ${pending} update(s)"
fi
