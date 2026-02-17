# OpenClaw Multi-Cloud Infrastructure Makefile

# Configuration
AZURE_DIR := infra/azure
ORACLE_DIR := infra/oracle
SSH_KEY := ~/.ssh/id_rsa
TF_PLAN := tfplan

.PHONY: help init-azure init-oracle validate-azure validate-oracle plan-azure plan-oracle deploy-azure deploy-oracle destroy-azure destroy-oracle ssh-azure ssh-oracle token-azure token-oracle

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# -------------------------------------------------------------------------
# Azure Targets
# -------------------------------------------------------------------------

init-azure: ## Initialize Terraform for Azure
	@echo "Initializing Azure..."
	@cd $(AZURE_DIR) && terraform init

validate-azure: ## Validate Azure configuration
	@echo "Validating Azure..."
	@cd $(AZURE_DIR) && terraform validate

plan-azure: validate-azure ## Preview Azure changes
	@echo "Planning Azure deployment..."
	@cd $(AZURE_DIR) && terraform plan -out=$(TF_PLAN)

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

init-oracle: ## Initialize Terraform for Oracle Cloud
	@echo "Initializing Oracle Cloud..."
	@cd $(ORACLE_DIR) && terraform init

validate-oracle: ## Validate Oracle configuration
	@echo "Validating Oracle..."
	@cd $(ORACLE_DIR) && terraform validate

plan-oracle: validate-oracle ## Preview Oracle changes
	@echo "Planning Oracle deployment..."
	@cd $(ORACLE_DIR) && terraform plan -out=$(TF_PLAN)

deploy-oracle: plan-oracle ## Deploy to Oracle Cloud
	@echo "Deploying to Oracle Cloud..."
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
