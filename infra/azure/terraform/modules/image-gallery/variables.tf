variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "gallery_name" {
  type = string
}

# Map of image-definition-name -> identifier (publisher/offer/sku).
# Each entry produces one azurerm_shared_image resource in the gallery.
variable "image_definitions" {
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
  }))
}

variable "hyper_v_generation" {
  type    = string
  default = "V2"
}

variable "trusted_launch_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
