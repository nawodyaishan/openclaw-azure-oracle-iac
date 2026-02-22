# OCI Authentication
# Note: The OCI Provider automatically reads authentication credentials 
# (tenancy, user, fingerprint, region, key file) from the standard 
# ~/.oci/config profile. Do not hardcode secrets here.

variable "compartment_ocid" {
  description = "OCI Compartment OCID (use Root/Tenancy OCID for personal use)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (e.g., your home IP)"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr must be a valid IPv4 CIDR notation (e.g., 192.168.1.0/24)."
  }
}

variable "custom_image_name" {
  description = "Name of the custom golden image built by Packer"
  type        = string
  default     = "openclaw-ubuntu-arm64-1"
  # Note: Since the timestamp is dynamic, we use a regex or prefix match in the data source, 
  # or you can override this if you want a specific image name.
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for VM auth"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    project    = "openclaw"
    managed_by = "terraform"
  }
}

variable "vm_shape" {
  description = "The shape of an instance (e.g., VM.Standard.E2.1.Micro or VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs for flexible shapes"
  type        = number
  default     = 4
}

variable "memory_in_gbs" {
  description = "Amount of Memory in GBs for flexible shapes"
  type        = number
  default     = 24
}
