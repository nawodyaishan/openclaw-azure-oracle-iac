# OpenClaw Azure Infrastructure

**Secure, Automated, and Cost-Effective OpenClaw Hosting on Azure.**

This repository contains Infrastructure as Code (IaC) using Terraform to deploy an optimized OpenClaw instance on Azure. It is tuned for the **Azure for Students** subscription but works with any standard subscription.

## ✨ Features

*   **Automation:**
    *   **One-Command Deploy:** Uses a `Makefile` to handle all Terraform commands.
    *   **Zero-Touch Install:** Automatically installs Node.js 22 and OpenClaw CLI via `cloud-init`.
*   **Security:**
    *   **Locked Down SSH:** Restricts SSH access to your specific IP address only.
    *   **Secure Token:** Auto-generates a cryptographically secure `GATEWAY_TOKEN` and injects it into the VM.
    *   **No Hardcoded Secrets:** All credentials are managed via Terraform state or generated on the fly.
*   **Reliability:**
    *   **Automated Backups:** Daily full backups retained for 7 days (Recovery Services Vault).
    *   **ARM64 Optimization:** Uses `Standard_B2pls_v2` (ARM64) for better price/performance.

## 🚀 Quick Start

### Prerequisites
1.  **Azure CLI:** `az login`
2.  **Terraform:** `brew install terraform` (or equivalent)
3.  **SSH Key:** `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa` (or use existing)

### 1. Configure
Create your variables file:
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```
**Important:** You **MUST** set `allowed_ssh_cidr` to your public IP (e.g., `1.2.3.4/32`) in `terraform.tfvars`.

### 2. Deploy
Run from the root directory:
```bash
make init     # First time only
make deploy   # Validates, Plans, and Applies
```

### 3. Connect & Configure
Once deployed, log in to your VM:
```bash
make ssh
```
*(No need to copy IPs, the Makefile handles it)*

Inside the VM, finish the setup:
```bash
# 1. Verify installation
openclaw --version

# 2. Link your accounts (WhatsApp, Telegram, etc.)
openclaw configure
```

### 4. Get Gateway Token
If you need your secure Gateway Token for external clients:
```bash
make token
```

## 🛠️ Operations (Makefile)

| Command | Description |
|---------|-------------|
| `make deploy` | Validates, plans, and applies changes to Azure. |
| `make ssh` | Automatically SSH into the VM. |
| `make token` | Reveal the secure `GATEWAY_TOKEN`. |
| `make check` | Check if OpenClaw is installed and running. |
| `make logs` | Stream installation logs (`cloud-init`). |
| `make destroy` | Tear down all infrastructure (Stop billing). |

## 📂 Folder Structure

```
openclaw-azure-iac/
├── Makefile                        # Shortcuts for common operations
├── infra/                          # Terraform configuration
│   ├── main.tf                     # VM, Networking, Backups, Security
│   ├── variables.tf                # Input definitions
│   ├── outputs.tf                  # IP, Token outputs
│   ├── cloud-init.tftpl            # Installation script template
│   ├── terraform.tfvars            # Your secrets/config (gitignored)
│   └── ...
└── README.md                       # This file
```

## 💰 Cost Estimate
*Based on Azure Central India pricing (may vary).*

| Resource | approximate Cost |
|----------|-----------------|
| **VM** (B2pls_v2, 2vCPU, 4GB RAM) | ~$25.00/mo |
| **Disk** (64GB SSD) | ~$3.00/mo |
| **Public IP** (Static) | ~$3.50/mo |
| **Backups** (Daily, 30GB avg) | ~$5.00/mo |
| **Total** | **~$36.50/mo** |

*Perfect for the $100/yr Azure for Students credit.*

## License
MIT