variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group" {
  type        = string
  default     = "rg-linux-desktop"
  description = "Resource group containing the Compute Gallery."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for the build VM."
}

variable "gallery_name" {
  type        = string
  default     = "clawGallery"
  description = "Azure Compute Gallery name."
}

variable "image_name" {
  type        = string
  default     = "claw-base"
  description = "Image definition name inside the gallery."
}

variable "image_version" {
  type        = string
  description = "Semantic version for the gallery image (e.g. 4.0.0)."
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for the build VM."
}
