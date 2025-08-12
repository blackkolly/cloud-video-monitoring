# Professional Terraform Variables
# This file defines all configurable parameters following enterprise standards

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralus"
}

variable "owner" {
  description = "Owner of the resources (for tagging and cost tracking)"
  type        = string
  default     = "student"
}

variable "cost_center" {
  description = "Cost center for billing (professional practice)"
  type        = string
  default     = "education"
}

# AKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.29.9"
}

variable "node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 1
  
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 5
    error_message = "Node count must be between 1 and 5."
  }
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "disk_size_gb" {
  description = "Disk size in GB for AKS nodes"
  type        = number
  default     = 30
}

# Network Configuration
variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Container Registry
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Database Configuration
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgres_sku" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "B_Standard_B1ms"  # Budget-friendly for student account
}

variable "postgres_storage_gb" {
  description = "PostgreSQL storage in GB"
  type        = number
  default     = 32  # Minimum for flexible server
}

# Monitoring and Logging
variable "enable_monitoring" {
  description = "Enable Azure Monitor for containers"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

# Security
variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "enable_private_cluster" {
  description = "Enable private AKS cluster (requires VPN for access)"
  type        = bool
  default     = false  # Set to false for student account simplicity
}

# Budget Control
variable "max_monthly_cost_usd" {
  description = "Maximum monthly cost in USD (for budget alerts)"
  type        = number
  default     = 45
}

variable "alert_threshold_percentage" {
  description = "Budget alert threshold percentage (main alert)"
  type        = number
  default     = 80
}
