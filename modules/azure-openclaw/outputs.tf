output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.this.location
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_size" {
  description = "Size of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.size
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.this.ip_address
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}"
}

output "gateway_token" {
  description = "Auto-generated OpenClaw Gateway Token (Secure)"
  value       = random_password.gateway_token.result
  sensitive   = true
}