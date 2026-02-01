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
  default     = "southeastasia"  # Singapore region
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
    project     = "openclaw"
    managed_by  = "terraform"
  }
}

# VM Configuration
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "openclaw-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine (B2pts_v2 = 2 vCPU, 4GB RAM, ARM64)"
  type        = string
  default     = "Standard_B2pts_v2"
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