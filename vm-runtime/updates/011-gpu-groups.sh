#!/usr/bin/env bash
# 011-gpu-groups.sh -- add azureuser to render + video so ROCm / OpenCL /
# VAAPI can open /dev/kfd and /dev/dri/* on the AMD V710.
#
# Without this, `rocminfo` and OpenCL enumeration fail with:
#   Unable to open /dev/kfd read-write: Permission denied
# even though the kernel module is loaded and the GPU is present.
#
# The VM is intentionally permissive (CLAUDE.md: "Permissive inside the VM
# is intentional"); /dev/kfd's default 0660 render ownership is the right
# gate — we just need group membership.
#
# Idempotent: usermod -aG is a no-op when already a member.
set -euo pipefail

ADMIN_USER="azureuser"

for grp in render video; do
    getent group "$grp" >/dev/null || groupadd -f "$grp"
    if ! id -nG "$ADMIN_USER" | tr ' ' '\n' | grep -qx "$grp"; then
        usermod -aG "$grp" "$ADMIN_USER"
        echo "[update-011] added $ADMIN_USER to $grp"
    fi
done

echo "[update-011] groups for $ADMIN_USER: $(id -nG "$ADMIN_USER")"
