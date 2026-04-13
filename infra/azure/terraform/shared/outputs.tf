output "resource_group_name" {
  description = "Terraform-managed Azure resource group name."
  value       = module.shared_infra.resource_group_name
}

output "location" {
  description = "Azure region."
  value       = module.shared_infra.location
}

output "virtual_network_id" {
  description = "Virtual network ID."
  value       = module.shared_infra.virtual_network_id
}

output "subnet_id" {
  description = "Subnet ID."
  value       = module.shared_infra.subnet_id
}

output "network_security_group_id" {
  description = "Network security group ID."
  value       = module.shared_infra.network_security_group_id
}

output "gallery_name" {
  description = "Azure Compute Gallery name."
  value       = module.image_gallery.gallery_name
}

output "gallery_id" {
  description = "Azure Compute Gallery ID."
  value       = module.image_gallery.gallery_id
}

output "image_definition_name" {
  description = "Azure Compute Gallery image definition name."
  value       = module.image_gallery.image_definition_name
}

output "image_definition_id" {
  description = "Azure Compute Gallery image definition ID."
  value       = module.image_gallery.image_definition_id
}
