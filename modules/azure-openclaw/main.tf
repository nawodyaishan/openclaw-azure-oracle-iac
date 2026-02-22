# Resource Group
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Subnet
resource "azurerm_subnet" "this" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "this" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Network Security Group
resource "azurerm_network_security_group" "this" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr #tfsec:ignore:azure-network-ssh-blocked-from-internet tfsec:ignore:azure-network-no-public-ingress
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*" #tfsec:ignore:azure-network-no-public-ingress
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*" #tfsec:ignore:azure-network-no-public-ingress
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Interface
resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  tags = var.tags
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# -------------------------------------------------------------------------
# Security (Token Generation)
# -------------------------------------------------------------------------

resource "random_password" "gateway_token" {
  length  = 32
  special = false
}

# Fetch the custom image built by Packer
data "azurerm_image" "custom" {
  name                = var.custom_image_name
  resource_group_name = var.custom_image_resource_group
}

# Virtual Machine - ARM64 B2pts_v2 (Azure for Students free tier eligible)
resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.vm_size # Standard_B2pts_v2: 2 vCPU, 4GB RAM, ARM64
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  # Use the custom Golden Image
  source_image_id = data.azurerm_image.custom.id


  custom_data = base64encode(templatefile("${path.module}/cloud-init.tftpl", {
    gateway_token = random_password.gateway_token.result
  }))

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# -------------------------------------------------------------------------
# Automated Backups (Phase 1.2 Sustainable Action Plan)
# -------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "this" {
  name                = "${var.vm_name}-rsv"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  soft_delete_enabled = true

  tags = var.tags
}

resource "azurerm_backup_policy_vm" "this" {
  name                = "${var.vm_name}-daily-policy"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }
}

resource "azurerm_backup_protected_vm" "this" {
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = azurerm_linux_virtual_machine.this.id
  backup_policy_id    = azurerm_backup_policy_vm.this.id
}