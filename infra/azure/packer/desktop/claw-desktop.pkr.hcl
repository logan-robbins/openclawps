packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

# claw-desktop-gpu: Ubuntu 24.04 + XFCE + LightDM + AMD Radeon Pro V710 driver
# + xrdp (port 3389) + Sunshine (Moonlight clients).
#
# This is the IMMUTABLE BASELINE image. Baked once per OS/driver/protocol upgrade.
# Everything else (OpenClaw, future variants) layers on top of this via the
# `os/claw-os.pkr.hcl` build, which uses this image as its `shared_image_gallery`
# source.

source "azure-arm" "claw-desktop-gpu" {
  subscription_id    = var.subscription_id
  use_azure_cli_auth = true
  location           = var.location
  vm_size            = var.vm_size

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"

  os_disk_size_gb = 128

  shared_image_gallery_destination {
    gallery_name        = var.gallery_name
    image_name          = "claw-desktop-gpu"
    image_version       = var.image_version
    resource_group      = var.resource_group
    replication_regions = [var.location]
  }

  security_type       = "TrustedLaunch"
  secure_boot_enabled = true
  vtpm_enabled        = true
}

build {
  sources = ["source.azure-arm.claw-desktop-gpu"]

  # Baseline desktop layer: XFCE, LightDM, AMD GPU driver, xrdp, Sunshine.
  # No agent, no Chrome, no application code.
  provisioner "shell" {
    scripts = [
      "../scripts/desktop/01-system-packages.sh",
      "../scripts/desktop/02-amd-gpu-driver.sh",
      "../scripts/desktop/03-display-config.sh",
      "../scripts/desktop/04-xrdp.sh",
      "../scripts/desktop/05-sunshine.sh",
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }

  # Cleanup and generalize
  provisioner "shell" {
    script          = "../scripts/99-cleanup.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }
}
