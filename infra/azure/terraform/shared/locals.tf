locals {
  fleet_manifest    = yamldecode(file("${path.root}/${var.fleet_manifest_path}"))
  azure             = local.fleet_manifest.azure
  image_definitions = local.azure.image_definitions
  shared_tags       = merge(try(local.azure.tags, {}), var.resource_tags)
}
