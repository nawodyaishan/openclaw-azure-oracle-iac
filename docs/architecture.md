# OpenClaw Multi-Cloud Infrastructure: Architecture & Deployment

This document provides a comprehensive overview of the OpenClaw Multi-Cloud Infrastructure project, including its architecture, technology stack, core components, and a step-by-step guide for deploying exclusively on Oracle Cloud's Always Free Tier.

---

## 🏗️ Architecture & Tech Stack

### Technology Stack
*   **Infrastructure as Code (IaC):** HashiCorp Terraform (`~> 1.0` or higher)
*   **Machine Image Baking:** HashiCorp Packer
*   **Cloud Providers:** 
    *   Microsoft Azure (Azure for Students optimized)
    *   Oracle Cloud Infrastructure (OCI) (Always Free Tier optimized)
*   **OS Base Image:** Canonical Ubuntu 22.04 LTS (Jammy Jellyfish) ARM64
*   **Pre-installed VM Tools:** `curl`, `git`, `tmux`, `openclaw` CLI
*   **Workflow Automation:** GNU Make (`Makefile`)

### Architectural Principles
1.  **Immutable Infrastructure:** We employ HashiCorp Packer to bake all necessary tools (like the OpenClaw CLI) into a custom "Golden Image". When a VM spins up, it boots from this pre-configured image rather than downloading packages on the fly, eliminating configuration drift and significantly speeding up boot times.
2.  **Zero-Touch Provisioning (ZTP):** Cloud provider-specific user data scripts (`cloud-init`) are used strictly for environment hydration—specifically, injecting the secure `GATEWAY_TOKEN` into the OS environment upon boot.
3.  **Principle of Least Privilege:** SSH access is tightly controlled via user-defined CIDR blocks (`allowed_ssh_cidr`). On Oracle, this is enforced via precise Network Security Groups (NSGs).
4.  **State Management:** Remote state backends are highly encouraged (Azure Storage Accounts or OCI Object Storage) to ensure state file consistency across teams and prevent local data loss.

---

## 🧩 Core Components

The repository is modularized by cloud provider, with shared automation via the root Makefile.

### 1. `packer/` (Image Factory)
Contains the declarative configurations for building Golden Images.
*  `packer/azure/openclaw.pkr.hcl`: Uses the `azure-arm` builder to create Azure Managed Images.
*  `packer/oracle/openclaw.pkr.hcl`: Uses the `oracle-oci` builder to create Custom OCI Images.

### 2. `infra/[cloud]/` (Provisioning Layer)
Contains the Terraform manifests for declaring cloud resources.
*   `main.tf`: The primary declaration file. Responsible for Network (VNet/VCN, Subnets), Security (NSGs, Security Rules), Compute (Virtual Machines), and dynamic Image Data Sources fetching the Packer-built image.
*   `variables.tf`: Input variable definitions to make the modules reusable and customizable.
*   `outputs.tf`: Important output values generated after deployment, such as the Public IP address and the generated `GATEWAY_TOKEN`.
*   `backend.tf.example`: A template for configuring remote state storage.
*   `cloud-init.tftpl`: The user-data template parsed by Terraform to inject the token.

### 3. `Makefile` (Operations Interface)
A unified command-line interface wrapping complex Packer and Terraform commands into simple phonetic targets like `make build-[cloud]` and `make deploy-[cloud]`.

---

## 🆓 Guide: Full Free Oracle Deployment

Oracle Cloud Infrastructure (OCI) offers an incredibly generous "Always Free" tier, including up to 4 ARM-based Ampere A1 Compute instances with 24GB of RAM. The OpenClaw IaC is purpose-built to fit entirely within this free tier.

**Note:** Depending on region demand, Oracle's free ARM instances can experience "Out of Host Capacity" errors. If you encounter this, retry the deployment later.

### Step 1: OCI Setup & Credentials
1. Create an [Oracle Cloud Account](https://www.oracle.com/cloud/free/).
2. Log in and navigate to **Identity & Security -> Users**. Select your user.
3. Under **API Keys**, click **Add API Key**. Generate a new key pair, download the Private Key (`.pem`), and click **Add**.
4. A configuration snippet will appear. Copy the `user`, `fingerprint`, `tenancy`, and `region` values.
5. Create a folder `~/.oci` on your local machine and move the `.pem` file there.

### Step 2: Initialize Configuration
Clone the repository and prepare the Oracle configuration:
```bash
git clone https://github.com/nawodyaishan/openclaw-azure-iac.git
cd openclaw-azure-iac

cp infra/oracle/terraform.tfvars.example infra/oracle/terraform.tfvars
```

### Step 3: Populate Variables
Open `infra/oracle/terraform.tfvars` and fill in the values you copied from Step 1:
*   `tenancy_ocid`, `user_ocid`, `fingerprint`, `region`
*   `private_key_path`: Typically `~/.oci/your-key-name.pem`
*   `compartment_ocid`: For free tier, this is usually the same as your `tenancy_ocid`.
*   `allowed_ssh_cidr`: Find your public IP (`curl ifconfig.me`) and append `/32` (e.g., `203.0.113.1/32`).

### Step 4: Export Packer Variables
Packer on OCI currently requires environment variables or a direct `~/.oci/config` file. To securely pass the variables you just defined:
```bash
export OCI_TENANCY_OCID="your_tenancy_ocid"
export OCI_USER_OCID="your_user_ocid"
export OCI_FINGERPRINT="your_fingerprint"
export OCI_KEY_FILE="~/.oci/your-key.pem"
export OCI_REGION="your_region"
export OCI_COMPARTMENT_OCID="your_compartment_ocid"

# You also need to specify target Availability Domain and Subnet to run the temporary build VM.
# Get these IDs from your OCI console (Networking -> VCNs).
export OCI_SUBNET_OCID="your_existing_subnet_id" 
export OCI_AVAILABILITY_DOMAIN="your_ad_name" 
```
*(Alternatively, configure the `~/.oci/config` profile standard).*

### Step 5: Build the Golden Image
Run the make target to begin baking the image. This process spins up a temporary VM, installs the OpenClaw CLI, saves the image, and terminates the temporary VM.
```bash
make build-oracle
```
**Important:** When the build finishes, it will output the new Image Name (e.g., `openclaw-ubuntu-arm64-1708535212`). Copy this name!

Edit `infra/oracle/terraform.tfvars` again and set:
```hcl
custom_image_name = "openclaw-ubuntu-arm64-1708535212"
```

### Step 6: Deploy Infrastructure
Now, deploy the actual Free Tier VM using your newly built image.
```bash
make init-oracle
make deploy-oracle
```
Type `yes` when prompted.

### Step 7: Connect and Configure
Once deployment finishes, Terraform will output your new IP address. Use the Makefile to connect securely:
```bash
make ssh-oracle
```

Once inside the VM, your `OPENCLAW_GATEWAY_TOKEN` is already loaded securely in the background. Link your external channels by running:
```bash
openclaw configure
```

### (Optional) Remote State
To ensure you never lose your Terrafrom state, configure an OCI Object Storage bucket:
```bash
make setup-state-oracle
```
Follow the on-screen instructions to format your `backend.conf` using S3-compatible Customer Secret Keys provided by Oracle entirely for free.
