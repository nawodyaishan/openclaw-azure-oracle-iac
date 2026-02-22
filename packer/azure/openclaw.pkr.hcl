packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.1"
    }
  }
}

variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}

variable "client_secret" {
  type    = string
  default = "${env("ARM_CLIENT_SECRET")}"
  sensitive = true
}

variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}

variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}

variable "resource_group_name" {
  type    = string
  default = "openclaw-packer-rg"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "image_name" {
  type    = string
  default = "openclaw-ubuntu-arm64-{{timestamp}}"
}

source "azure-arm" "ubuntu_arm64" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-arm64"
  image_version   = "latest"

  vm_size = "Standard_B2pts_v2" # Same ARM64 VM size used in OpenClaw

  location = var.location
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = var.image_name

  # Allow packer to build in this RG and clean up
  build_resource_group_name = var.resource_group_name
}

build {
  sources = ["source.azure-arm.ubuntu_arm64"]

  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "echo 'Updating packages...'",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "echo 'Installing base tools...'",
      "sudo apt-get install -y curl git tmux",
      "echo 'Installing OpenClaw CLI...'",
      "curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash",
      "echo 'Validating OpenClaw installation...'",
      "export NVM_DIR=\"$HOME/.nvm\"",
      "[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\" || echo 'NVM not found'",
      "openclaw --version || echo 'OpenClaw installed but requires shell restart.' "
    ]
  }

  # Azure specifics for preparing the agent
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
  }
}
