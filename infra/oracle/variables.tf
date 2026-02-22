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
}

variable "custom_image_name" {
  description = "Name of the custom golden image built by Packer"
  type        = string
  default     = "openclaw-ubuntu-x86_64"
  # Note: Since the timestamp is dynamic, we use a regex or prefix match in the data source, 
  # or you can override this if you want a specific image name.
}
