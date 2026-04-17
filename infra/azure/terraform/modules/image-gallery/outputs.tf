output "gallery_name" {
  value = azurerm_shared_image_gallery.this.name
}

output "gallery_id" {
  value = azurerm_shared_image_gallery.this.id
}

output "image_definition_names" {
  value = [for img in azurerm_shared_image.this : img.name]
}

output "image_definition_ids" {
  value = { for k, img in azurerm_shared_image.this : k => img.id }
}
