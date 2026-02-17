# OpenClaw Multi-Cloud Infrastructure

**Secure, Automated Hosting for OpenClaw on Azure & Oracle Cloud.**

This repository contains Infrastructure as Code (IaC) using Terraform to deploy an optimized OpenClaw instance on two cloud providers. It follows **SRE Best Practices** (Infrastructure as Code, Immutable Infrastructure) and leverages **Free Tier** resources where available.

## ✨ Features

### Multi-Cloud Support
*   **Azure:** Tuned for Azure for Students (`Standard_B2pls_v2`).
*   **Oracle Cloud:** Tuned for Always Free Tier (`VM.Standard.A1.Flex`).

### Automation
*   **One-Command Deploy:** Uses a `Makefile` to simplify Terraform workflows.
*   **Zero-Touch Install:** Automatically installs Node.js 22 and OpenClaw CLI via `cloud-init`.

### Security
*   **Locked Down SSH:** Restricts SSH access to your specific IP `allowed_ssh_cidr`.
*   **Secure Token:** Auto-generates a cryptographically secure `GATEWAY_TOKEN` and injects it into the VM environment.
*   **Granular Network Security:**
    *   **Oracle:** Uses **Network Security Groups (NSGs)** instead of broad Security Lists for precise firewall rules.
    *   **Azure:** Uses **Application Security Groups (ASGs)** pattern via NSG rules.

### Reliability
*   **Encrypted State:** Sensitive data (tokens) are marked `sensitive` in Terraform.
*   **Remote State (Optional):** Supports storing Terraform state in Azure Storage or OCI Object Storage for safety.
*   **Automated Backups:**
    *   **Azure:** Integrated Recovery Services Vault (Daily Backups).
    *   **Oracle:** (Manual setup recommended for Free Tier).

## 🚀 Quick Start

### Prerequisites
1.  **Cloud Account:** Azure Subscription OR Oracle Cloud Account.
2.  **Terraform:** `brew install terraform`
3.  **SSH Key:** `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa`
4.  *(Optional)* **Azure CLI / OCI CLI** for remote state setup.
5.  *(Optional)* **DevOps Tools:** `brew install tflint tfsec infracost terraform-docs`

### 1. Configure

#### Option A: Azure (Student)
```bash
cd infra/azure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
# Set 'allowed_ssh_cidr' to your public IP (e.g., 1.2.3.4/32)
```

#### Option B: Oracle Cloud (Free Tier)
```bash
cd infra/oracle
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```
**Required Oracle Variables:**
*   `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`, `region`, `allowed_ssh_cidr`.

### 2. Setup Remote State (Recommended)
Store your infrastructure state in the cloud to prevent data loss.

**For Azure:**
```bash
make setup-state-azure  # Creates Storage Account & Generates backend.conf
make init-azure         # Initializes with remote backend
```

**For Oracle:**
```bash
make setup-state-oracle # Shows instructions for OCI Object Storage
# Follow instructions to create backend.conf
make init-oracle        # Initializes with remote backend
```

*(You can skip this to use local state, but backing up `infra/` is critical).*

### 3. Deploy

Run from the root directory:

**Deploy to Azure:**
```bash
make init-azure     # If not run in step 2
make deploy-azure   # Validates, Plans, and Applies
```

**Deploy to Oracle:**
```bash
make init-oracle    # If not run in step 2
make deploy-oracle  # Validates, Plans, and Applies
```

### 4. Connect & Configure
The Makefile handles IP retrieval and SSH commands automatically.

**Connect:**
```bash
make ssh-azure   # Connects as 'azureuser'
# OR
make ssh-oracle  # Connects as 'ubuntu'
```

**Configure:**
Inside the VM (works for both):
```bash
# 1. Verify installation
openclaw --version

# 2. Link your accounts (WhatsApp, Telegram, etc.)
# Note: Your GATEWAY_TOKEN is already set in /etc/environment
openclaw configure
```

### 5. Get Gateway Token
If you need your secure Gateway Token for external clients:
```bash
make token-azure
# OR
make token-oracle
```

## 🛠️ Operations (Makefile)

### Deployment & Access
| Target | Description |
|--------|-------------|
| `deploy-[cloud]` | Deploy entire stack. |
| `ssh-[cloud]` | SSH into VM. |
| `destroy-[cloud]` | Destroy resources. |
| `token-[cloud]` | Reveal the auto-generated `GATEWAY_TOKEN`. |
| `setup-state-[cloud]` | Setup Remote State Storage. |

### DevOps Best Practices
| Target | Description | Tool Required |
|--------|-------------|---------------|
| `make lint` | Check code style & errors. | `tflint` |
| `make security` | Scan for security vulnerabilities. | `tfsec` |
| `make cost` | Estimate monthly cloud costs. | `infracost` |
| `make docs` | Auto-generate README inputs/outputs. | `terraform-docs` |

## 📂 Folder Structure

```
openclaw-azure-iac/
├── Makefile                        # Multi-cloud commands
├── infra/
│   ├── azure/                      # Azure Terraform config
│   │   ├── backend.tf              # Remote State Config
│   │   ├── main.tf                 # VM, Networking, Backups
│   │   └── ...
│   └── oracle/                     # Oracle Terraform config
│       ├── backend.tf              # Remote State Config
│       ├── main.tf                 # VCN, NSG, Compute
│       └── ...
└── README.md                       # This file
```

## 💰 Cost Comparison (Estimated: 2026 Feb 18 via Infracost)

| Feature | Azure (Student B2pls_v2) | Oracle (Always Free A1) |
|---------|--------------------------|-------------------------|
| **Compute** | $16.35/mo | **$0.00/mo** |
| **Storage** | $3.31/mo (64GB Disk) | **$0.00/mo (50GB)** |
| **Network** | $3.65/mo (Public IP) | **$0.00/mo** |
| **Backup** | ~$16.31/mo (Daily + Retention) | Manual/Scripts |
| **Total** | **~$39.62/mo*** | **$0.00/mo** |

*\*Azure costs are often covered by Student Credits ($100/yr). Oracle is Always Free.*

## ❓ Troubleshooting

### Oracle: "Out of Host Capacity"
**Error:** `500 Internal Server Error` or `Out of capacity`.
**Cause:** The Ampere A1 Free Tier is popular and sometimes regions run out of capacity.
**Solution:**
1.  Retry the deployment later (`make deploy-oracle`).
2.  Switch regions if possible (requires new account/tenancy).
3.  Upgrade to Pay-As-You-Go (you still get the free tier, but with higher priority).

### SSH Connection Refused
**Cause:** Your IP address changed or `allowed_ssh_cidr` is incorrect.
**Solution:**
1.  Check your IP: `curl ifconfig.me`
2.  Update `infra/[cloud]/terraform.tfvars`.
3.  Run `make deploy-[cloud]` to update the Security Group rules.

## License
MIT