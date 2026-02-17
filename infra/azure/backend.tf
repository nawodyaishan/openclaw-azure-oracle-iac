# Uncomment and configure for remote state storage
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate-rg"
#     storage_account_name = "tfstateocl"
#     container_name       = "tfstate"
#     key                  = "openclaw.terraform.tfstate"
#   }
# }