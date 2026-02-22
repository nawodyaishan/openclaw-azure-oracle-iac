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
