packer {
  required_plugins {
    oracle = {
      source  = "github.com/hashicorp/oracle"
      version = "~> 1.1"
    }
  }
}

variable "tenancy_ocid" {
  type    = string
  default = "${env("OCI_TENANCY_OCID")}"
}

variable "user_ocid" {
  type    = string
  default = "${env("OCI_USER_OCID")}"
}

variable "fingerprint" {
  type    = string
  default = "${env("OCI_FINGERPRINT")}"
}

variable "key_file" {
  type    = string
  default = "${env("OCI_KEY_FILE")}"
}

variable "region" {
  type    = string
  default = "${env("OCI_REGION")}"
}

variable "compartment_ocid" {
  type    = string
  default = "${env("OCI_COMPARTMENT_OCID")}"
}

variable "subnet_ocid" {
  type    = string
  default = "${env("OCI_SUBNET_OCID")}"
  description = "A subnet to spin up the build instance"
}

variable "availability_domain" {
  type    = string
  default = "${env("OCI_AVAILABILITY_DOMAIN")}"
}

source "oracle-oci" "ubuntu_arm64" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  key_file         = var.key_file
  region           = var.region
  compartment_ocid = var.compartment_ocid

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
    ocpus         = 1
    memory_in_gbs = 6
  }

  image_name      = "openclaw-ubuntu-arm64-{{timestamp}}"
  ssh_username    = "ubuntu"
}

build {
  sources = ["source.oracle-oci.ubuntu_arm64"]

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
      "curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | sudo bash",
      "echo 'Validating OpenClaw installation...'",
      "openclaw --version"
    ]
  }
}
