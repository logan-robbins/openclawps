module "shared_infra" {
  source = "../modules/shared-infra"

  location                    = local.azure.location
  resource_group_name         = local.azure.resource_group_name
  virtual_network_name        = local.azure.virtual_network_name
  subnet_name                 = local.azure.subnet_name
  network_security_group_name = local.azure.network_security_group_name
  address_space               = local.azure.address_space
  subnet_prefixes             = local.azure.subnet_prefixes
  tags                        = local.shared_tags
}

module "image_gallery" {
  source = "../modules/image-gallery"

  location               = module.shared_infra.location
  resource_group_name    = module.shared_infra.resource_group_name
  gallery_name           = local.azure.gallery_name
  image_definition_name  = local.azure.image_definition_name
  image_identifier       = local.image_identifier
  hyper_v_generation     = try(local.azure.hyper_v_generation, "V2")
  trusted_launch_enabled = try(local.azure.trusted_launch_enabled, true)
  tags                   = local.shared_tags
}
