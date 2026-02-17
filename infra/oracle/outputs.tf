output "public_ip" {
  value = oci_core_instance.main.public_ip
}

output "ssh_connection" {
  value = "ssh ubuntu@${oci_core_instance.main.public_ip}"
  description = "Connect using: ssh ubuntu@<public_ip>"
}

output "gateway_token" {
  value     = random_password.gateway_token.result
  sensitive = true
}
