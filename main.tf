# Azure RM provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
  # The backend configuration is required to save state to Azure storage. 
  # Specify the configuration in backend.tfvars
  # Then run "terraform init -backend-config=backend.tfvars"
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# Data element to access Azure AD
data azurerm_client_config current {}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = join("", [var.application, var.environment, "_rg"])
  location = var.location
  tags = {
    application = var.application
    environment = var.environment
  }
}

# Get the key for the azure storage account
data "azurerm_storage_account" "stg" {
  name                = var.database_bacpac_storage_account
  resource_group_name = var.database_bacpac_storage_account_rg
}
