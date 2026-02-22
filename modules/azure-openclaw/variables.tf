variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "openclaw-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralindia" # Central India - Azure for Students allowed region
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    project    = "openclaw"
    managed_by = "terraform"
  }
}

# VM Configuration
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "openclaw-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine (B2pls_v2 = 2 vCPU, 4GB RAM, ARM64)"
  type        = string
  default     = "Standard_B2pls_v2"
}

variable "disk_size_gb" {
  description = "Size of the virtual machine OS disk in GB"
  type        = string
  default     = "64"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM authentication"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to access via SSH (e.g., your public IP)"
  type        = string
  default     = "0.0.0.0/0" # Default is open, but user should override this

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr must be a valid IPv4 CIDR notation (e.g., 192.168.1.0/24)."
  }
}

variable "custom_image_name" {
  description = "Name of the custom golden image built by Packer"
  type        = string
  default     = "openclaw-ubuntu-arm64-latest" # You should override this with the actual build name
}

variable "custom_image_resource_group" {
  description = "Resource group where the custom image is stored"
  type        = string
  default     = "openclaw-packer-rg"
}
