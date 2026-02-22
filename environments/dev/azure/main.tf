module "openclaw" {
  source = "../../../modules/azure-openclaw"

  resource_group_name         = var.resource_group_name
  location                    = var.location
  environment                 = var.environment
  tags                        = var.tags
  vm_name                     = var.vm_name
  vm_size                     = var.vm_size
  disk_size_gb                = var.disk_size_gb
  admin_username              = var.admin_username
  ssh_public_key_path         = var.ssh_public_key_path
  allowed_ssh_cidr            = var.allowed_ssh_cidr
  custom_image_name           = var.custom_image_name
  custom_image_resource_group = var.custom_image_resource_group
}
