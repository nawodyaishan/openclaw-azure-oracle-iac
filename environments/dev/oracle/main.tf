module "openclaw" {
  source = "../../../modules/oracle-openclaw"

  compartment_ocid    = var.compartment_ocid
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  custom_image_name   = var.custom_image_name
  ssh_public_key_path = var.ssh_public_key_path
  tags                = var.tags
}
