# -------------------------------------------------------------------------
# Network (VCN & Subnet)
# -------------------------------------------------------------------------

resource "oci_core_vcn" "this" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "openclaw-vcn"
  dns_label      = "openclaw"
  freeform_tags  = var.tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "openclaw-ig"
  vcn_id         = oci_core_vcn.this.id
  freeform_tags  = var.tags
}

resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "openclaw-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }

  freeform_tags = var.tags
}

resource "oci_core_subnet" "this" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.this.id
  display_name      = "openclaw-public-subnet"
  dns_label         = "public"
  security_list_ids = [oci_core_vcn.this.default_security_list_id] # Default allows strict ingress, we use NSG
  route_table_id    = oci_core_route_table.this.id

  freeform_tags = var.tags
}

# -------------------------------------------------------------------------
# Security (Network Security Group)
# -------------------------------------------------------------------------

resource "oci_core_network_security_group" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "openclaw-nsg"
  freeform_tags  = var.tags
}

# Ingress: SSH (Restricted to User IP)
resource "oci_core_network_security_group_security_rule" "ssh_ingress" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.allowed_ssh_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

# Ingress: HTTP (Open)
resource "oci_core_network_security_group_security_rule" "http_ingress" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

# Ingress: HTTPS (Open)
resource "oci_core_network_security_group_security_rule" "https_ingress" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

# Egress: Allow All
resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

# -------------------------------------------------------------------------
# Security (Token Generation)
# -------------------------------------------------------------------------

resource "random_password" "this" {
  length  = 32
  special = false
}

# -------------------------------------------------------------------------
# Compute (Always Free Ampere A1)
# -------------------------------------------------------------------------

# Get the custom Golden Image built by Packer
data "oci_core_images" "custom_image" {
  compartment_id = var.compartment_ocid
  display_name   = var.custom_image_name
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_instance" "this" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "openclaw-vm"
  shape               = var.vm_shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.custom_image.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.this.id
    nsg_ids          = [oci_core_network_security_group.this.id]
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(templatefile("${path.module}/cloud-init.tftpl", {
      gateway_token = random_password.this.result
    }))
  }

  freeform_tags = var.tags

  # Ensure NSG rules exist before creating instance (soft dependency)
  depends_on = [
    oci_core_network_security_group_security_rule.ssh_ingress
  ]
}
