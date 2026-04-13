#!/usr/bin/env bash
# 99-cleanup.sh -- clean up for image generalization
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Clean apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Clean temp files
rm -rf /tmp/* /var/tmp/openclaw-compile-cache/*

# Remove SSH host keys (regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

# Clear logs
find /var/log -type f -exec truncate -s 0 {} \;

# Clear bash history
rm -f /root/.bash_history /home/azureuser/.bash_history

# Azure Linux Agent deprovision (generalizes the VM for image capture)
/usr/sbin/waagent -force -deprovision+user
sync
