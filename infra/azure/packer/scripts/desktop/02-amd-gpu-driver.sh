#!/usr/bin/env bash
# 02-amd-gpu-driver.sh -- install AMD Radeon Pro V710 driver (amdgpu + workstation graphics)
# Per MS Learn: https://learn.microsoft.com/azure/virtual-machines/linux/azure-n-series-amd-gpu-driver-linux-installation-guide
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# AMD's Ubuntu 22.04 (jammy) installer also serves 24.04 (noble) per AMD's repo layout
# Use ROCm 6.1.4 release as documented for V710
AMDGPU_INSTALLER_URL="https://repo.radeon.com/amdgpu-install/6.1.4/ubuntu/noble/amdgpu-install_6.1.60104-1_all.deb"

wget -q -O /tmp/amdgpu-install.deb "$AMDGPU_INSTALLER_URL"
apt-get install -y /tmp/amdgpu-install.deb
rm -f /tmp/amdgpu-install.deb

# Workstation graphics + AMF video encoding (needed for Sunshine VAAPI hw encode)
# No ROCm/OpenCL — this is a desktop image, not a compute image
amdgpu-install -y \
  --usecase=workstation,amf \
  --vulkan=pro \
  --no-32 \
  --accept-eula

# Ensure amdgpu loads on boot
if grep -q '^blacklist amdgpu' /etc/modprobe.d/blacklist.conf 2>/dev/null; then
  sed -i '/^blacklist amdgpu/d' /etc/modprobe.d/blacklist.conf
fi
echo "amdgpu" > /etc/modules-load.d/amdgpu.conf

# X11 OutputClass to prefer amdgpu (BusID-specific Device section is written at boot
# by /opt/claw/boot.sh, since BusID can vary per VM)
mkdir -p /usr/share/X11/xorg.conf.d
cat > /usr/share/X11/xorg.conf.d/10-amdgpu.conf <<'XORG'
Section "OutputClass"
    Identifier "Card0"
    MatchDriver "amdgpu"
    Driver "amdgpu"
    Option "PrimaryGPU" "yes"
EndSection
XORG

# Initramfs needs rebuild after blacklist removal + module load config
update-initramfs -uk all
