variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group" {
  type        = string
  default     = "rg-claw-westus"
  description = "Resource group containing the Compute Gallery."
}

variable "location" {
  type        = string
  default     = "westus"
  description = "Azure region for the build VM."
}

variable "gallery_name" {
  type        = string
  default     = "clawGallery"
  description = "Azure Compute Gallery name."
}

variable "image_version" {
  type        = string
  description = "Semantic version for the gallery image (e.g. 1.0.0)."
}

variable "vm_size" {
  type        = string
  default     = "Standard_NV8ads_V710_v5"
  description = "VM size for the build VM. The baseline targets the AMD Radeon Pro V710 SKU so the AMD driver compiles against the same kernel/PCI ID it will run against."
}
