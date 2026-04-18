packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

# claw-os: single bake on top of AMD's pre-installed V710 marketplace image.
#
# The marketplace image already provides: kernel pin, amdgpu kernel driver,
# ROCm/AMF userspace, Secure Boot signed modules. We add ONLY the desktop
# layer (XFCE, LightDM, dummy Xorg, xrdp, Sunshine) and the agent layer
# (Node, Chrome, Claude Code, Tailscale, Xvfb-backed agent services,
# vm-runtime payload). Decision rationale: the standalone baseline/ Terraform
# already covers the "deploy a generic GPU desktop" case directly from the
# marketplace image, so a separate claw-desktop image was redundant.

source "azure-arm" "claw-os" {
  subscription_id    = var.subscription_id
  use_azure_cli_auth = true
  location           = var.location
  vm_size            = var.vm_size

  os_type = "Linux"

  # AMD V710 marketplace image (Ubuntu + amdgpu pre-installed).
  image_publisher = "amdinc1746636494855"
  image_offer     = "nvv5_v710_linux_rocm_image"
  image_sku       = "planid125"
  image_version   = "1.0.2"

  plan_info {
    plan_name      = "planid125"
    plan_product   = "nvv5_v710_linux_rocm_image"
    plan_publisher = "amdinc1746636494855"
  }

  shared_image_gallery_destination {
    gallery_name        = var.gallery_name
    image_name          = "claw-os"
    image_version       = var.image_version
    resource_group      = var.resource_group
    replication_regions = [var.location]
  }

  # AMD marketplace image does not support Trusted Launch (no signed kernel/
  # initramfs chain) — leave security_type unset to use the default "Standard"
  # security profile (Packer for Azure rejects an explicit "Standard").
}

build {
  sources = ["source.azure-arm.claw-os"]

  # Desktop layer: XFCE + LightDM + dummy Xorg + xrdp + Sunshine
  # (no AMD driver script — marketplace base already has it)
  provisioner "shell" {
    scripts = [
      "../scripts/desktop/01-system-packages.sh",
      "../scripts/desktop/03-display-config.sh",
      "../scripts/desktop/04-xrdp.sh",
      "../scripts/desktop/05-sunshine.sh",
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }

  # Application layer: Node + OpenClaw + Chrome + Claude Code + Tailscale +
  # system setup + Xvfb-backed agent services
  provisioner "shell" {
    scripts = [
      "../scripts/os/01-nodejs-openclaw.sh",
      "../scripts/os/02-chrome.sh",
      "../scripts/os/03-claude-code.sh",
      "../scripts/os/04-tailscale.sh",
      "../scripts/os/05-system-setup.sh",
      "../scripts/os/06-openclaw-services.sh",
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }

  # Stage vm-runtime boot files onto the image.
  # Tarballs must be pre-built before running packer build:
  #   tar czf /tmp/packer-defaults.tar.gz -C vm-runtime/defaults .
  #   tar czf /tmp/packer-updates.tar.gz  -C vm-runtime/updates  .
  provisioner "file" {
    source      = "../../../../vm-runtime/lifecycle/boot.sh"
    destination = "/tmp/boot.sh"
  }
  provisioner "file" {
    source      = "../../../../vm-runtime/lifecycle/run-updates.sh"
    destination = "/tmp/run-updates.sh"
  }
  provisioner "file" {
    source      = "../../../../vm-runtime/lifecycle/start-claude.sh"
    destination = "/tmp/start-claude.sh"
  }
  provisioner "file" {
    source      = "../../../../vm-runtime/lifecycle/verify.sh"
    destination = "/tmp/verify.sh"
  }
  provisioner "file" {
    source      = "/tmp/packer-defaults.tar.gz"
    destination = "/tmp/packer-defaults.tar.gz"
  }
  provisioner "file" {
    source      = "/tmp/packer-updates.tar.gz"
    destination = "/tmp/packer-updates.tar.gz"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/claw/defaults /opt/claw/updates",
      "sudo cp /tmp/boot.sh /opt/claw/boot.sh",
      "sudo cp /tmp/run-updates.sh /opt/claw/run-updates.sh",
      "sudo cp /tmp/start-claude.sh /opt/claw/start-claude.sh",
      "sudo cp /tmp/verify.sh /opt/claw/verify.sh",
      "sudo chmod +x /opt/claw/boot.sh /opt/claw/run-updates.sh /opt/claw/start-claude.sh /opt/claw/verify.sh",
      "sudo tar xzf /tmp/packer-defaults.tar.gz -C /opt/claw/defaults/",
      "sudo tar xzf /tmp/packer-updates.tar.gz -C /opt/claw/updates/",
      "sudo chmod +x /opt/claw/updates/*.sh 2>/dev/null || true",
      "rm -f /tmp/boot.sh /tmp/run-updates.sh /tmp/start-claude.sh /tmp/verify.sh /tmp/packer-defaults.tar.gz /tmp/packer-updates.tar.gz",
    ]
  }

  # Cleanup and generalize
  provisioner "shell" {
    script          = "../scripts/99-cleanup.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }
}
