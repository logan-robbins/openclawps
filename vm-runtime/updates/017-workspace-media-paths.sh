#!/usr/bin/env bash
# 017-workspace-media-paths.sh -- teach the OpenClaw/Claude Code agent about the
# hardcoded media-root allowlist (source: openclaw dist/local-roots-BrPriMlc.js
# buildMediaLocalRoots). Writing to plain /tmp/ yields "Outside allowed folders"
# in the chat UI. Fix: refreshed workspace docs + a ~/workspace/tmp -> /tmp/
# symlink so /tmp/* can at least be *referenced* through an allowed root.
#
# Runs as root via run-updates.sh; user-scoped ownership fixed at the end.
set -euo pipefail

DEFAULTS="/opt/claw/defaults/workspace"
WS="/mnt/claw-data/workspace"
TAG="[update-017]"

# Refresh the three docs that changed. Overwrite is acceptable because the
# previous live versions matched the repo defaults (verified 2026-04-21); any
# future drift should be synced back into the repo before shipping an update.
for f in AGENTS.md TOOLS.md CLAUDE.md; do
    if [ -f "$DEFAULTS/$f" ]; then
        cp "$DEFAULTS/$f" "$WS/$f"
        chown azureuser:azureuser "$WS/$f"
        echo "$TAG refreshed $WS/$f"
    fi
done

# Symlink ~/workspace/tmp -> /tmp/ so agents can reference /tmp files via a
# path that starts with an allowed root (/mnt/claw-data/workspace). Client-side
# UI string-check passes via this; server-side realpath may still reject the
# final fetch, which is documented in AGENTS.md.
LINK="$WS/tmp"
if [ -L "$LINK" ]; then
    current=$(readlink "$LINK")
    if [ "$current" = "/tmp/" ] || [ "$current" = "/tmp" ]; then
        echo "$TAG $LINK already points to /tmp/"
    else
        rm -f "$LINK"
        sudo -u azureuser ln -s /tmp/ "$LINK"
        echo "$TAG repointed $LINK -> /tmp/ (was: $current)"
    fi
elif [ -e "$LINK" ]; then
    echo "$TAG WARNING: $LINK exists and is not a symlink; leaving it alone"
else
    sudo -u azureuser ln -s /tmp/ "$LINK"
    echo "$TAG created $LINK -> /tmp/"
fi

# Ensure /tmp/openclaw exists with the perms the resolver wants (0700, owned by
# azureuser). The gateway normally creates this at startup, but seeding it here
# avoids a first-attachment race and documents the expectation in one place.
TMPDIR="/tmp/openclaw"
if [ ! -d "$TMPDIR" ]; then
    install -d -m 0700 -o azureuser -g azureuser "$TMPDIR"
    echo "$TAG created $TMPDIR (0700 azureuser)"
else
    chmod 0700 "$TMPDIR"
    chown azureuser:azureuser "$TMPDIR"
fi
