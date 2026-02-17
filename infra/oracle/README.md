## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_oci"></a> [oci](#provider\_oci) | 8.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [oci_core_instance.main](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_instance) | resource |
| [oci_core_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_internet_gateway) | resource |
| [oci_core_network_security_group.openclaw_nsg](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group_security_rule.egress_all](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.http_ingress](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.https_ingress](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.ssh_ingress](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_route_table.main](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_route_table) | resource |
| [oci_core_subnet.public](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_vcn.main](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_vcn) | resource |
| [random_password.gateway_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [oci_core_images.ubuntu_arm](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/core_images) | data source |
| [oci_identity_availability_domains.ads](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_availability_domains) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | CIDR block allowed to SSH (e.g., your home IP) | `string` | n/a | yes |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | OCI Compartment OCID (use Root/Tenancy OCID for personal use) | `string` | n/a | yes |
| <a name="input_fingerprint"></a> [fingerprint](#input\_fingerprint) | OCI API Key Fingerprint | `string` | n/a | yes |
| <a name="input_private_key_path"></a> [private\_key\_path](#input\_private\_key\_path) | Path to OCI API Private Key | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | OCI Region (e.g., us-ashburn-1) | `string` | n/a | yes |
| <a name="input_ssh_public_key_path"></a> [ssh\_public\_key\_path](#input\_ssh\_public\_key\_path) | Path to SSH public key | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_tenancy_ocid"></a> [tenancy\_ocid](#input\_tenancy\_ocid) | OCI Tenancy OCID | `string` | n/a | yes |
| <a name="input_user_ocid"></a> [user\_ocid](#input\_user\_ocid) | OCI User OCID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_token"></a> [gateway\_token](#output\_gateway\_token) | n/a |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | n/a |
| <a name="output_ssh_connection"></a> [ssh\_connection](#output\_ssh\_connection) | Connect using: ssh ubuntu@<public\_ip> |
