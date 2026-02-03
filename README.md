# OpenClaw Azure Infrastructure

Terraform configuration for provisioning Azure infrastructure to host OpenClaw, optimized for Azure for Students subscription.

## Overview

This repository contains Infrastructure as Code (IaC) using Terraform to deploy:
- Ubuntu 22.04 LTS ARM64 Virtual Machine
- Virtual Network with subnet
- Network Security Group (SSH, HTTP, HTTPS)
- Static Public IP
- Automated OpenClaw installation via cloud-init

## Folder Structure

```
openclaw-azure/
├── infra/                          # Terraform configuration
│   ├── providers.tf                # Azure provider configuration
│   ├── variables.tf                # Input variable definitions
│   ├── main.tf                     # Main resources (VM, networking)
│   ├── outputs.tf                  # Output values (IP, SSH command)
│   ├── backend.tf                  # Remote state config (optional)
│   ├── cloud-init.yaml             # VM initialization script
│   ├── terraform.tfvars            # Your variable values (gitignored)
│   └── terraform.tfvars.example    # Example variable values
├── src/                            # Application source (if any)
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
```

## Prerequisites

### 1. Azure Account
- Azure for Students subscription (or any Azure subscription)
- Note: Azure for Students has region restrictions. Allowed regions:
  - `centralindia` (Central India)
  - `eastasia` (East Asia)
  - `uaenorth` (UAE North)
  - `indonesiacentral` (Indonesia Central)
  - `malaysiawest` (Malaysia West)

### 2. Local Tools

#### Azure CLI

**macOS:**
```bash
brew install azure-cli
```

**Ubuntu/Debian:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Windows (PowerShell as Administrator):**
```powershell
# Option 1: Using winget
winget install -e --id Microsoft.AzureCLI

# Option 2: Using MSI installer
# Download from: https://aka.ms/installazurecliwindows

# Option 3: Using Chocolatey
choco install azure-cli
```

#### Terraform

**macOS:**
```bash
brew install terraform
```

**Ubuntu/Debian:**
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

**Windows (PowerShell as Administrator):**
```powershell
# Option 1: Using winget
winget install -e --id Hashicorp.Terraform

# Option 2: Using Chocolatey
choco install terraform

# Option 3: Manual install
# Download from: https://developer.hashicorp.com/terraform/downloads
# Extract and add to PATH
```

### 3. SSH Key

**macOS/Linux:**
```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_openclaw

# Verify it exists
ls ~/.ssh/azure_openclaw.pub
```

**Windows (PowerShell or Git Bash):**
```powershell
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\azure_openclaw

# Verify it exists
dir $env:USERPROFILE\.ssh\azure_openclaw.pub
```

> **Windows Note:** Update `ssh_public_key_path` in terraform.tfvars to use Windows path:
> ```hcl
> ssh_public_key_path = "C:/Users/YourUsername/.ssh/azure_openclaw.pub"
> ```

## VM Specifications

| Property | Value |
|----------|-------|
| **VM Size** | Standard_B2pls_v2 |
| **vCPUs** | 2 |
| **RAM** | 4 GB |
| **Architecture** | ARM64 |
| **OS** | Ubuntu 22.04 LTS |
| **Disk** | 64 GB Standard LRS |
| **Region** | Central India |

## Cost Estimate (Azure for Students)

| Resource | Monthly Cost |
|----------|-------------|
| B2pls_v2 VM (4GB) | ~$25 |
| 64GB Disk | ~$3 |
| Static Public IP | ~$3.50 |
| **Total** | **~$31.50/month** |

Your $100 Azure for Students credit covers ~3 months of usage.

> **Note:** B2pts_v2 (1GB RAM) is free tier but insufficient for builds. B2pls_v2 (4GB) is recommended.

## Step-by-Step Deployment Guide

### Step 1: Clone the Repository
```bash
git clone https://github.com/stoXmod/openclaw-azure
cd openclaw-azure
```

### Step 2: Login to Azure
```bash
az login

# Verify subscription
az account show --query "{name:name, id:id}"
```

### Step 3: Configure Variables
```bash
cd infra

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**terraform.tfvars contents:**
```hcl
subscription_id     = "your-azure-subscription-id"
resource_group_name = "openclaw-rg"
location            = "centralindia"
environment         = "dev"

# VM Configuration
vm_name             = "openclaw-vm"
vm_size             = "Standard_B2pls_v2"
disk_size_gb        = 64
admin_username      = "azureuser"
ssh_public_key_path = "~/.ssh/azure_openclaw.pub"
```

### Step 4: Initialize Terraform
```bash
terraform init
```

### Step 5: Validate Configuration
```bash
terraform validate
```

### Step 6: Preview Changes
```bash
terraform plan
```

### Step 7: Deploy
```bash
terraform apply
```
Type `yes` when prompted.

### Step 8: Get Connection Details
```bash
terraform output
```

Output:
```
public_ip_address = "x.x.x.x"
ssh_connection = "ssh azureuser@x.x.x.x"
```

## Post-Deployment Setup

### Connect to VM
```bash
ssh -i ~/.ssh/azure_openclaw azureuser@<public-ip>
```

### Check Cloud-Init Status
```bash
# Wait for cloud-init to complete
sudo cloud-init status --wait

# View logs if needed
sudo tail -f /var/log/cloud-init-output.log
```

### Configure OpenClaw
```bash
# Run OpenClaw setup
openclaw setup

# Follow the interactive prompts to configure your API keys
```

### Verify Installation
```bash
openclaw --version
openclaw --help
```

## Managing Infrastructure

### View Current State
```bash
terraform show
```

### Update Infrastructure
```bash
# After modifying .tf files
terraform plan
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```
Type `yes` when prompted.

## Troubleshooting

### Region Restriction Error (403 Forbidden)
```
Error: RequestDisallowedByAzure: Resource was disallowed by Azure
```
**Solution:** Change `location` in terraform.tfvars to an allowed region (centralindia, eastasia, etc.)

### SSH Connection Refused
```bash
# Check if VM is running
az vm show -g openclaw-rg -n openclaw-vm --query "powerState"

# Check NSG rules
az network nsg rule list -g openclaw-rg --nsg-name openclaw-vm-nsg -o table
```

### Cloud-Init Failed
```bash
# Check status
sudo cloud-init status

# View detailed logs
sudo cat /var/log/cloud-init-output.log
```

### Low Memory Issues
Add swap space:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Security Notes

- SSH is open to all IPs by default. For production, restrict `source_address_prefix` in the NSG to your IP.
- `terraform.tfvars` contains sensitive data - it's gitignored by default.
- Never commit `.tfstate` files to version control.

## Files Not to Commit

These are automatically gitignored:
- `*.tfvars` (except `.tfvars.example`)
- `*.tfstate*`
- `.terraform/`
- `*.tfplan`

## License

MIT