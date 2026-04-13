#!/usr/bin/env bash
# 002-test-marker.sh -- writes a marker to verify update flow works
echo "v2-upgrade-applied" > /mnt/claw-data/v2-marker.txt
chown azureuser:azureuser /mnt/claw-data/v2-marker.txt
echo "[update-002] Wrote v2 upgrade marker"
