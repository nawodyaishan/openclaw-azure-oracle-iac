#!/usr/bin/env bash
set -euo pipefail

# Create directories
mkdir -p modules/oracle-openclaw
mkdir -p modules/azure-openclaw
mkdir -p environments/dev/oracle
mkdir -p environments/dev/azure

# 1. Oracle Refactor
mv infra/oracle/main.tf modules/oracle-openclaw/
mv infra/oracle/variables.tf modules/oracle-openclaw/
mv infra/oracle/outputs.tf modules/oracle-openclaw/
mv infra/oracle/cloud-init.tftpl modules/oracle-openclaw/

mv infra/oracle/providers.tf environments/dev/oracle/
mv infra/oracle/terraform.tfvars environments/dev/oracle/ 2>/dev/null || true

cat << 'INNER_EOF' > environments/dev/oracle/main.tf
module "openclaw" {
  source = "../../../modules/oracle-openclaw"

  compartment_ocid    = var.compartment_ocid
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  custom_image_name   = var.custom_image_name
  ssh_public_key_path = var.ssh_public_key_path
  tags                = var.tags
}
INNER_EOF

# Copy the original variables to the environment level
cp modules/oracle-openclaw/variables.tf environments/dev/oracle/variables.tf

cat << 'INNER_EOF' > environments/dev/oracle/outputs.tf
output "public_ip" {
  value = module.openclaw.public_ip
}
output "ssh_connection" {
  value       = module.openclaw.ssh_connection
  description = "Connect using: ssh ubuntu@<public_ip>"
}
output "gateway_token" {
  value     = module.openclaw.gateway_token
  sensitive = true
}
INNER_EOF

# 2. Azure Refactor
mv infra/azure/main.tf modules/azure-openclaw/
mv infra/azure/variables.tf modules/azure-openclaw/
mv infra/azure/outputs.tf modules/azure-openclaw/
mv infra/azure/cloud-init.tftpl modules/azure-openclaw/

mv infra/azure/providers.tf environments/dev/azure/
mv infra/azure/terraform.tfvars environments/dev/azure/ 2>/dev/null || true

cat << 'INNER_EOF' > environments/dev/azure/main.tf
module "openclaw" {
  source = "../../../modules/azure-openclaw"

  subscription_id             = var.subscription_id
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
INNER_EOF

cp modules/azure-openclaw/variables.tf environments/dev/azure/variables.tf

cat << 'INNER_EOF' > environments/dev/azure/outputs.tf
output "resource_group_name" {
  value = module.openclaw.resource_group_name
}
output "resource_group_location" {
  value = module.openclaw.resource_group_location
}
output "vm_name" {
  value = module.openclaw.vm_name
}
output "vm_size" {
  value = module.openclaw.vm_size
}
output "public_ip_address" {
  value = module.openclaw.public_ip_address
}
output "ssh_connection" {
  value = module.openclaw.ssh_connection
}
output "gateway_token" {
  value     = module.openclaw.gateway_token
  sensitive = true
}
INNER_EOF

