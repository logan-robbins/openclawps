variable "fleet_manifest_path" {
  description = "Path to the fleet manifest YAML file, relative to this Terraform root."
  type        = string
}

variable "resource_tags" {
  description = "Additional tags merged onto every managed Azure resource."
  type        = map(string)
  default     = {}
}
