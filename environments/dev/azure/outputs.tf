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
