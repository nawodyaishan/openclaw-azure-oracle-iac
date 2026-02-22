# OpenClaw Multi-Cloud Infrastructure Makefile

# Configuration
AZURE_DIR := environments/dev/azure
ORACLE_DIR := environments/dev/oracle
SSH_KEY := ~/.ssh/id_rsa
TF_PLAN := tfplan

# Ensure Cloud Credentials are automatically passed down to subshells
export ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_SUBSCRIPTION_ID ARM_TENANT_ID

.PHONY: help init-azure init-oracle validate-azure validate-oracle plan-azure plan-oracle deploy-azure deploy-oracle destroy-azure destroy-oracle ssh-azure ssh-oracle token-azure token-oracle build-azure build-oracle

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# -------------------------------------------------------------------------
# DevOps Best Practices
# -------------------------------------------------------------------------

lint: ## Lint Terraform code (tflint + fmt)
	@echo "running terraform fmt..."
	@terraform fmt -recursive
	@echo "running tflint..."
	@if command -v tflint >/dev/null; then tflint --recursive; else echo "⚠️ tflint not installed. 'brew install tflint'"; fi

security: ## Scan for security issues (tfsec)
	@echo "running tfsec..."
	@if command -v tfsec >/dev/null; then tfsec .; else echo "⚠️ tfsec not installed. 'brew install tfsec'"; fi

cost: ## Estimate costs (infracost)
	@echo "running infracost..."
	@if command -v infracost >/dev/null; then \
		infracost breakdown --path . || echo "⚠️ Cost estimation failed (Missing API Key?)."; \
	else \
		echo "⚠️ infracost not installed. 'brew install infracost'"; \
	fi

docs: ## Generate Documentation (terraform-docs)
	@echo "Generating docs..."
	@if command -v terraform-docs >/dev/null; then \
		terraform-docs markdown table modules/azure-openclaw > modules/azure-openclaw/README.md; \
		terraform-docs markdown table modules/oracle-openclaw > modules/oracle-openclaw/README.md; \
		echo "✅ Updated modules/azure-openclaw/README.md"; \
		echo "✅ Updated modules/oracle-openclaw/README.md"; \
	else \
		echo "⚠️ terraform-docs not installed. 'brew install terraform-docs'"; \
	fi

# -------------------------------------------------------------------------
# Azure Targets
# -------------------------------------------------------------------------

setup-state-azure: ## Create Azure Storage Account for Remote State
	@echo "Creating Azure Remote State resources..."
	@RANDOM_ID=$$(openssl rand -hex 6); \
	SA_NAME="openclawstate$$RANDOM_ID"; \
	az group create --name openclaw-state-rg --location centralindia; \
	az storage account create --name $$SA_NAME --resource-group openclaw-state-rg --sku Standard_LRS --encryption-services blob; \
	az storage container create --name tfstate --account-name $$SA_NAME; \
	echo "resource_group_name  = \"openclaw-state-rg\"" > $(AZURE_DIR)/backend.conf; \
	echo "storage_account_name = \"$$SA_NAME\"" >> $(AZURE_DIR)/backend.conf; \
	echo "container_name       = \"tfstate\"" >> $(AZURE_DIR)/backend.conf; \
	echo "key                  = \"terraform.tfstate\"" >> $(AZURE_DIR)/backend.conf; \
	echo 'terraform { backend "azurerm" {} }' > $(AZURE_DIR)/backend.tf; \
	echo "✅ Azure Remote State setup complete. Configuration saved to $(AZURE_DIR)/backend.conf and backend.tf enabled."

init-azure: ## Initialize Terraform for Azure (Auto-detects Local/Remote)
	@echo "Initializing Azure..."
	@if [ -f $(AZURE_DIR)/backend.tf ]; then \
		echo "🌍 Remote State detected (backend.tf exists). Using backend.conf..."; \
		cd $(AZURE_DIR) && terraform init -backend-config=backend.conf; \
	else \
		echo "⚠️ No backend.tf found. Running standard init (Local State). Run 'make setup-state-azure' to switch to Remote State."; \
		cd $(AZURE_DIR) && terraform init; \
	fi

validate-azure: ## Validate Azure configuration
	@echo "Validating Azure..."
	@cd $(AZURE_DIR) && terraform validate

plan-azure: validate-azure ## Preview Azure changes
	@echo "Planning Azure deployment..."
	@cd $(AZURE_DIR) && terraform plan -out=$(TF_PLAN)

build-azure: ## Build custom Golden Image for Azure using Packer
	@echo "Building Azure Image with Packer..."
	@cd packer/azure && packer init . && \
	packer build \
		-var "client_id=$(ARM_CLIENT_ID)" \
		-var "client_secret=$(ARM_CLIENT_SECRET)" \
		-var "subscription_id=$(ARM_SUBSCRIPTION_ID)" \
		-var "tenant_id=$(ARM_TENANT_ID)" \
		openclaw.pkr.hcl

deploy-azure: plan-azure ## Deploy to Azure
	@echo "Deploying to Azure..."
	@cd $(AZURE_DIR) && terraform apply $(TF_PLAN)
	@rm $(AZURE_DIR)/$(TF_PLAN)

destroy-azure: ## Destroy Azure infrastructure
	@echo "Destroying Azure infrastructure..."
	@cd $(AZURE_DIR) && terraform destroy

ssh-azure: ## SSH into Azure VM
	@echo "Connecting to Azure VM..."
	@IP=$$(cd $(AZURE_DIR) && terraform output -raw public_ip_address); \
	ssh -i $(SSH_KEY) azureuser@$$IP

token-azure: ## Get Azure Gateway Token
	@echo "Retrieving Azure Gateway Token..."
	@cd $(AZURE_DIR) && terraform output -raw gateway_token

# -------------------------------------------------------------------------
# Oracle Cloud Targets
# -------------------------------------------------------------------------

setup-state-oracle: ## Guide for Oracle Remote State setup
	@echo "Oracle Remote State Setup Instructions:"
	@echo "1. Create an Object Storage Bucket named 'tfstate' in your OCI Console."
	@echo "2. Generate 'Customer Secret Keys' (S3 Compatible) for your user in OCI Console."
	@echo "3. Run this command to initialize backend config: echo 'terraform { backend \"s3\" {} }' > $(ORACLE_DIR)/backend.tf"
	@echo "4. Create a file '$(ORACLE_DIR)/backend.conf' with the following content:"
	@echo "   bucket   = \"tfstate\""
	@echo "   key      = \"terraform.tfstate\""
	@echo "   region   = \"us-ashburn-1\" (or your region)"
	@echo "   endpoint = \"https://{namespace}.compat.objectstorage.{region}.oraclecloud.com\""
	@echo "   access_key = \"YOUR_ACCESS_KEY\""
	@echo "   secret_key = \"YOUR_SECRET_KEY\""
	@echo "   skip_region_validation      = true"
	@echo "   skip_credentials_validation = true"
	@echo "   skip_metadata_api_check     = true"
	@echo "   force_path_style            = true"
	@echo ""
	@echo "💡 Use 'oci os ns get' to find your namespace."

init-oracle: ## Initialize Terraform for Oracle Cloud (Auto-detects Local/Remote)
	@echo "Initializing Oracle Cloud..."
	@if [ -f $(ORACLE_DIR)/backend.tf ]; then \
		echo "🌍 Remote State detected (backend.tf exists). Using backend.conf..."; \
		cd $(ORACLE_DIR) && terraform init -backend-config=backend.conf; \
	else \
		echo "⚠️ No backend.tf found. Running standard init (Local State). Run 'make setup-state-oracle' for instructions."; \
		cd $(ORACLE_DIR) && terraform init; \
	fi

validate-oracle: ## Validate Oracle configuration
	@echo "Validating Oracle..."
	@cd $(ORACLE_DIR) && terraform validate

plan-oracle: validate-oracle ## Preview Oracle changes (ARM A1.Flex Shape)
	@echo "Planning Oracle deployment (VM.Standard.A1.Flex)..."
	@cd $(ORACLE_DIR) && terraform plan -out=$(TF_PLAN)

build-oracle: ## Build custom Golden Image for Oracle using Packer (ARM A1.Flex Shape)
	@echo "Building Oracle Image (ARM64) with Packer..."
	@cd packer/oracle && packer init . && packer build -var-file=oracle.auto.pkrvars.hcl openclaw.pkr.hcl

deploy-oracle: plan-oracle ## Deploy to Oracle Cloud (ARM A1.Flex Shape)
	@echo "Deploying to Oracle Cloud (VM.Standard.A1.Flex)..."
	@cd $(ORACLE_DIR) && terraform apply $(TF_PLAN)
	@rm $(ORACLE_DIR)/$(TF_PLAN)

destroy-oracle: ## Destroy Oracle infrastructure
	@echo "Destroying Oracle infrastructure..."
	@cd $(ORACLE_DIR) && terraform destroy

ssh-oracle: ## SSH into Oracle VM
	@echo "Connecting to Oracle VM..."
	@IP=$$(cd $(ORACLE_DIR) && terraform output -raw public_ip); \
	ssh -i $(SSH_KEY) ubuntu@$$IP

token-oracle: ## Get Oracle Gateway Token
	@echo "Retrieving Oracle Gateway Token..."
	@cd $(ORACLE_DIR) && terraform output -raw gateway_token

clean: ## Clean up plan files
	@rm -f $(AZURE_DIR)/$(TF_PLAN) $(ORACLE_DIR)/$(TF_PLAN)
