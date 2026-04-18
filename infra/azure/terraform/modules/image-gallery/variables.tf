variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "gallery_name" {
  type = string
}

# Map of image-definition-name -> identifier + optional marketplace purchase_plan.
# Each entry produces one azurerm_shared_image resource in the gallery.
# purchase_plan must match the source marketplace image when the bake derives
# from a marketplace VM (Azure rejects publish if they differ).
variable "image_definitions" {
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    purchase_plan = optional(object({
      name      = string
      publisher = string
      product   = string
    }))
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
