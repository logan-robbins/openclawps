variable "vm_name" {
  type        = string
  default     = "baseline-desktop"
  description = "Name for the VM (also used as the hostname, NIC/IP/disk prefix)."
}

variable "location" {
  type        = string
  default     = "westus"
  description = "Azure region. Must have capacity for Standard_NV*ads_V710_v5."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-linux-gpu-westus"
  description = "Resource group. Created by this root if absent."
}

variable "vm_size" {
  type        = string
  default     = "Standard_NV8ads_V710_v5"
  description = "SKU. Must be NV*ads_V710_v5 family to get the AMD Radeon Pro V710 GPU."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 128
  description = "OS disk size. AMD ROCm/amdgpu install requires >64 GiB per MS docs."
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Login name for SSH and RDP. Passwordless sudo is granted in cloud-init."
}

variable "admin_ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the SSH public key added to ~azureuser/.ssh/authorized_keys. Required (Azure rejects VMs with no SSH key)."
}

variable "admin_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Admin password. If empty, one is generated. Used for both SSH password auth AND RDP. Surface via `terraform output -raw admin_password`."
}

variable "address_space" {
  type        = list(string)
  default     = ["10.10.0.0/16"]
  description = "VNet CIDR."
}

variable "subnet_prefix" {
  type        = string
  default     = "10.10.0.0/24"
  description = "Subnet CIDR inside the VNet."
}

variable "allowed_source_ip" {
  type        = string
  default     = "*"
  description = "Source IP / CIDR allowed on 22/3389/47984-48010. '*' opens the VM to the internet (fine for a dev/eval box; tighten for production)."
}

variable "tags" {
  type = map(string)
  default = {
    project = "gpu-remote-desktop"
    purpose = "baseline"
  }
}
