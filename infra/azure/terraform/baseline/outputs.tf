output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "public_ip" {
  value       = azurerm_public_ip.this.ip_address
  description = "Public IP for SSH (22), RDP (3389), Sunshine (47984-48010)."
}

output "admin_username" {
  value = var.admin_username
}

output "admin_password" {
  value       = local.effective_password
  sensitive   = true
  description = "Admin password. `terraform output -raw admin_password` to retrieve."
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}"
}

output "rdp_client_hint" {
  value = "Microsoft Remote Desktop / FreeRDP -> ${azurerm_public_ip.this.ip_address}:3389 (user: ${var.admin_username}, password: see admin_password output)"
}

output "sunshine_web_ui" {
  value       = "https://${azurerm_public_ip.this.ip_address}:47990"
  description = "Sunshine web UI. First visit: set a password, pair Moonlight clients via PIN."
}
