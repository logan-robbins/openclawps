resource "azurerm_shared_image_gallery" "this" {
  name                = var.gallery_name
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "OpenClawps image gallery"
  tags                = var.tags
}

resource "azurerm_shared_image" "this" {
  for_each = var.image_definitions

  name                = each.key
  gallery_name        = azurerm_shared_image_gallery.this.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  hyper_v_generation  = var.hyper_v_generation

  identifier {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
  }

  dynamic "purchase_plan" {
    for_each = each.value.purchase_plan != null ? [each.value.purchase_plan] : []
    content {
      name      = purchase_plan.value.name
      publisher = purchase_plan.value.publisher
      product   = purchase_plan.value.product
    }
  }

  trusted_launch_enabled = var.trusted_launch_enabled
  tags                   = var.tags
}
