variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI API Private Key"
  type        = string
}

variable "region" {
  description = "OCI Region (e.g., us-ashburn-1)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI Compartment OCID (use Root/Tenancy OCID for personal use)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (e.g., your home IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "custom_image_name" {
  description = "Name of the custom golden image built by Packer"
  type        = string
  default     = "openclaw-ubuntu-arm64"
  # Note: Since the timestamp is dynamic, we use a regex or prefix match in the data source, 
  # or you can override this if you want a specific image name.
}
