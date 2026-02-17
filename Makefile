# OpenClaw Azure Infrastructure Makefile

# Configuration
TF_DIR := infra
SSH_KEY := ~/.ssh/id_rsa
TF_PLAN := tfplan

.PHONY: help init validate plan deploy destroy ssh check clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform (download providers, modules)
	@echo "Initializing Terraform..."
	@cd $(TF_DIR) && terraform init

validate: ## Validate Terraform configuration syntax
	@echo "Validating configuration..."
	@cd $(TF_DIR) && terraform validate

plan: validate ## Preview changes before applying
	@echo "Planning deployment..."
	@cd $(TF_DIR) && terraform plan -out=$(TF_PLAN)

deploy: plan ## Deploy infrastructure to Azure
	@echo "Deploying to Azure..."
	@cd $(TF_DIR) && terraform apply $(TF_PLAN)
	@rm $(TF_DIR)/$(TF_PLAN)

destroy: ## Destroy all infrastructure (DANGER!)
	@echo "Destroying infrastructure..."
	@cd $(TF_DIR) && terraform destroy

ssh: ## SSH into the OpenClaw VM
	@echo "Connecting to VM..."
	@IP=$$(cd $(TF_DIR) && terraform output -raw public_ip_address); \
	ssh -i $(SSH_KEY) azureuser@$$IP

token: ## Get the secure OpenClaw Gateway Token
	@echo "Retrieving Gateway Token..."
	@cd $(TF_DIR) && terraform output -raw gateway_token

check: ## Verify OpenClaw installation status on remote VM
	@echo "Checking OpenClaw status..."
	@IP=$$(cd $(TF_DIR) && terraform output -raw public_ip_address); \
	ssh -i $(SSH_KEY) azureuser@$$IP "openclaw --version && echo '✅ OpenClaw is installed' || echo '❌ OpenClaw not found'"

logs: ## Tail cloud-init logs on remote VM
	@echo "Streaming cloud-init logs..."
	@IP=$$(cd $(TF_DIR) && terraform output -raw public_ip_address); \
	ssh -i $(SSH_KEY) azureuser@$$IP "tail -f /var/log/cloud-init-output.log"

clean: ## Clean up local Terraform state backup and plan files
	@echo "Cleaning up..."
	@rm -f $(TF_DIR)/$(TF_PLAN)
	@rm -f $(TF_DIR)/*.backup
