packer {
  required_plugins {
    oracle = {
      source  = "github.com/hashicorp/oracle"
      version = "~> 1.1"
    }
  }
}

# -----------------------------------------------------------------------------
# Infrastructure Variables
# Note: OCI Authentication (tenancy, user, fingerprint, key_file, region) 
# is automatically read from the ~/.oci/config profile securely.
# -----------------------------------------------------------------------------

variable "compartment_ocid" {
  type    = string
}

variable "subnet_ocid" {
  type    = string
  description = "A subnet to spin up the build instance"
}

variable "availability_domain" {
  type    = string
}

# -----------------------------------------------------------------------------
# Builder
# -----------------------------------------------------------------------------

source "oracle-oci" "ubuntu_arm64" {
  compartment_ocid    = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_ocid         = var.subnet_ocid

  # Ubuntu 22.04 ARM64
  base_image_filter {
    compartment_id = var.compartment_ocid
    operating_system = "Canonical Ubuntu"
    operating_system_version = "22.04"
  }

  shape = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  image_name      = "openclaw-ubuntu-arm64-{{timestamp}}"
  ssh_username    = "ubuntu"
}

# -----------------------------------------------------------------------------
# Provisioners
# -----------------------------------------------------------------------------

build {
  sources = [
    "source.oracle-oci.ubuntu_arm64"
  ]

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
      "echo 'Setting up PATH for OpenClaw in .bashrc...'",
      "echo 'export PATH=\"$HOME/.openclaw/bin:$PATH\"' >> $HOME/.bashrc",
      "echo 'Validating OpenClaw installation...'",
      "export PATH=\"$HOME/.openclaw/bin:$PATH\"",
      "openclaw --version"
    ]
  }
}
