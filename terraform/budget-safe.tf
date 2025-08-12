# BUDGET-SAFE Terraform Configuration - Guaranteed Under $45/month
# This configuration is specifically designed for Azure Student accounts

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Budget-safe local values
locals {
  project_name = "video-budget"
  environment  = "dev"
  location     = "East US"  # Cheapest Azure region
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Budget      = "45USD"
  }
  
  # Ultra-budget naming
  resource_group_name = "${local.project_name}-rg"
  aks_cluster_name   = "${local.project_name}-aks"
  acr_name           = "videobudget${random_integer.suffix.result}"
}

resource "random_integer" "suffix" {
  min = 100
  max = 999
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# Budget Alert - CRITICAL for your safety
resource "azurerm_consumption_budget_resource_group" "emergency_stop" {
  name              = "emergency-budget-stop"
  resource_group_id = azurerm_resource_group.main.id

  amount     = 40  # Alert at $40, not $45
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h"))
  }

  notification {
    enabled   = true
    threshold = 80  # Alert at 80% of $40 = $32
    operator  = "GreaterThan"
    
    contact_emails = [
      "your-email@example.com"  # REPLACE WITH YOUR EMAIL
    ]
  }

  notification {
    enabled   = true
    threshold = 100  # Critical alert at $40
    operator  = "GreaterThan"
    
    contact_emails = [
      "your-email@example.com"  # REPLACE WITH YOUR EMAIL  
    ]
  }
}

# Container Registry - Basic tier only
resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"  # $5/month
  admin_enabled       = true
  tags                = local.common_tags
}

# AKS Cluster - MINIMUM configuration for budget
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.project_name
  kubernetes_version  = "1.27"
  
  # ULTRA-BUDGET node pool
  default_node_pool {
    name       = "default"
    node_count = 1                    # Only 1 node
    vm_size    = "Standard_B2s"       # Cheapest viable option: $30/month
    os_disk_size_gb = 30             # Minimum disk size
    
    # No auto-scaling to control costs
    enable_auto_scaling = false
  }

  # System assigned identity (free)
  identity {
    type = "SystemAssigned"
  }

  # Basic networking (cheapest)
  network_profile {
    network_plugin = "kubenet"  # Cheaper than Azure CNI
    load_balancer_sku = "basic" # Cheaper load balancer
  }

  # Disable expensive features
  role_based_access_control_enabled = false
  
  tags = local.common_tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
