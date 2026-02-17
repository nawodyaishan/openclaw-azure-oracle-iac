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
*   **Automated Backups:**
    *   **Azure:** Integrated Recovery Services Vault (Daily Backups).
    *   **Oracle:** (Manual setup recommended for Free Tier).

## 🚀 Quick Start

### Prerequisites
1.  **Cloud Account:** Azure Subscription OR Oracle Cloud Account.
2.  **Terraform:** `brew install terraform`
3.  **SSH Key:** `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa`

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
*   `tenancy_ocid`: Found in Profile -> Tenancy.
*   `user_ocid`: Found in Profile -> User Settings.
*   `fingerprint`: Generated when you add an API Key.
*   `private_key_path`: Path to your `.pem` key file.
*   `region`: e.g., `us-ashburn-1`.
*   `allowed_ssh_cidr`: Your public IP.

### 2. Deploy

Run from the root directory:

**Deploy to Azure:**
```bash
make init-azure     # First time only
make deploy-azure   # Validates, Plans, and Applies
```

**Deploy to Oracle:**
```bash
make init-oracle    # First time only
make deploy-oracle  # Validates, Plans, and Applies
```

### 3. Connect & Configure
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

### 4. Get Gateway Token
If you need your secure Gateway Token for external clients:
```bash
make token-azure
# OR
make token-oracle
```

## 🛠️ Operations (Makefile)

| Target | Description |
|--------|-------------|
| `deploy-azure` | Deploy entire stack to Azure. |
| `deploy-oracle` | Deploy entire stack to Oracle Cloud. |
| `ssh-azure` | SSH into Azure VM. |
| `ssh-oracle` | SSH into Oracle VM. |
| `destroy-azure` | Destroy Azure resources (Stop billing). |
| `destroy-oracle` | Destroy Oracle resources. |
| `token-[cloud]` | Reveal the auto-generated `GATEWAY_TOKEN`. |

## 📂 Folder Structure

```
openclaw-azure-iac/
├── Makefile                        # Multi-cloud commands
├── infra/
│   ├── azure/                      # Azure Terraform config
│   │   ├── main.tf                 # VM, Networking, Backups
│   │   ├── variables.tf
│   │   └── ...
│   └── oracle/                     # Oracle Terraform config
│       ├── main.tf                 # VCN, NSG, Compute
│       ├── variables.tf
│       └── ...
└── README.md                       # This file
```

## 💰 Cost Comparison

| Feature | Azure (Student B2pls_v2) | Oracle (Always Free A1) |
|---------|--------------------------|-------------------------|
| **CPU** | 2 vCPU | **4 OCPU (Ampere ARM64)** |
| **RAM** | 4 GB | **24 GB** |
| **Cost** | ~$36/mo (Covered by Setup Credit) | **$0.00/mo** |
| **Backups** | Integrated (Paid) | Manual/Scripts (Free) |

*Oracle Free Tier is highly recommended for personal use due to the generous resources.*

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