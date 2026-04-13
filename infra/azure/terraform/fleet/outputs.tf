output "claw_public_ips" {
  description = "Public IP addresses keyed by claw name."
  value = {
    for claw_name, claw in module.claw_vm :
    claw_name => claw.public_ip_address
  }
}

output "claw_vnc_urls" {
  description = "VNC URLs keyed by claw name."
  value = {
    for claw_name, claw in module.claw_vm :
    claw_name => "vnc://${claw.public_ip_address}:5900"
  }
}

output "claw_vm_passwords" {
  description = "Generated VM passwords keyed by claw name."
  sensitive   = true
  value = {
    for claw_name, password in random_password.vm_password :
    claw_name => password.result
  }
}

output "claw_data_disk_ids" {
  description = "Managed data disk IDs keyed by claw name."
  value = {
    for claw_name, claw in module.claw_vm :
    claw_name => claw.data_disk_id
  }
}
