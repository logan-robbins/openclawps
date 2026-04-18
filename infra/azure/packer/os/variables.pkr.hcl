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
  default     = "clawGalleryWest"
  description = "Azure Compute Gallery name (subscription-unique; westus uses ...West to avoid eastus collision)."
}

variable "image_version" {
  type        = string
  description = "Semantic version for the claw-os image (e.g. 1.0.0)."
}

variable "base_image_version" {
  type        = string
  default     = "1.0.0"
  description = "Version of the claw-desktop-gpu image to build on top of."
}

variable "vm_size" {
  type        = string
  default     = "Standard_NV8ads_V710_v5"
  description = "VM size for the build VM. Match the deploy SKU so the AMD driver from the baseline runs against the same kernel/GPU at bake."
}
