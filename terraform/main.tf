# Professional-grade Terraform configuration for Video Streaming Platform on Azure AKS
# This follows enterprise best practices and industry standards

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # Professional practice: Use remote state for team collaboration
  # For initial deployment, we'll use local state
  # Uncomment and configure below for team collaboration
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "terraformstate"
  #   container_name       = "tfstate"
  #   key                  = "video-streaming.terraform.tfstate"
  # }
}

# Configure Azure Provider
provider "azurerm" {
  skip_provider_registration = true
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Local values for consistent naming and tagging
locals {
  # Naming convention: {project}-{environment}-{resource}
  project_name = "video-streaming"
  environment  = var.environment
  location     = var.location
  
  # Common tags - professional standard for resource management
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CreatedDate = timestamp()
    CostCenter  = var.cost_center
  }
  
  # Resource naming
  resource_group_name = "${local.project_name}-${local.environment}-rg"
  aks_cluster_name   = "${local.project_name}-${local.environment}-aks"
  acr_name           = "${replace(local.project_name, "-", "")}${local.environment}acr${random_integer.suffix.result}"
  key_vault_name     = "vs-${local.environment}-kv-${random_integer.suffix.result}"
  
  # Network configuration
  vnet_name          = "${local.project_name}-${local.environment}-vnet"
  aks_subnet_name    = "${local.project_name}-${local.environment}-aks-subnet"
  
  # Budget optimization for student account
  node_count         = var.environment == "dev" ? 1 : 2
  vm_size           = var.environment == "dev" ? "Standard_B2s" : "Standard_D2s_v3"
}

# Random integer for unique resource names
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
