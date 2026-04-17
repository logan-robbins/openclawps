packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

# claw-os: builds on top of claw-desktop-gpu, adds OpenClaw + Chrome + Claude Code
# + Tailscale + Xvfb-backed agent services + boot infrastructure.
# This is the image fleet VMs deploy from.

source "azure-arm" "claw-os" {
  subscription_id    = var.subscription_id
  use_azure_cli_auth = true
  location           = var.location
  vm_size            = var.vm_size

  os_type = "Linux"

  # Start from the claw-desktop-gpu baseline gallery image
  shared_image_gallery {
    subscription   = var.subscription_id
    resource_group = var.resource_group
    gallery_name   = var.gallery_name
    image_name     = "claw-desktop-gpu"
    image_version  = var.base_image_version
  }

  shared_image_gallery_destination {
    gallery_name        = var.gallery_name
    image_name          = "claw-os"
    image_version       = var.image_version
    resource_group      = var.resource_group
    replication_regions = [var.location]
  }

  security_type       = "TrustedLaunch"
  secure_boot_enabled = true
  vtpm_enabled        = true
}

build {
  sources = ["source.azure-arm.claw-os"]

  # Application-layer installs (desktop already present from claw-desktop-gpu)
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

  # Stage vm-runtime boot files onto the image
  # Tarballs must be pre-built before running packer build:
  #   tar czf /tmp/packer-defaults.tar.gz -C vm-runtime/defaults .
  #   tar czf /tmp/packer-updates.tar.gz -C vm-runtime/updates .
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

  # Untar and move staged files into place
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
