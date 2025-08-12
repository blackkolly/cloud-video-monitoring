# BUDGET-SAFE Variables - Locked to $45 budget

variable "budget_limit_usd" {
  description = "Hard budget limit in USD"
  type        = number
  default     = 45
  
  validation {
    condition     = var.budget_limit_usd <= 45
    error_message = "Budget cannot exceed $45 for student account safety."
  }
}

variable "emergency_email" {
  description = "Email for budget alerts - REQUIRED"
  type        = string
  default     = "your-email@example.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.emergency_email))
    error_message = "Please provide a valid email for budget alerts."
  }
}

variable "allow_overage" {
  description = "Allow deployment if it might exceed budget"
  type        = bool
  default     = false
}

# Fixed budget-safe configuration - DO NOT CHANGE
locals {
  budget_safe_config = {
    vm_size              = "Standard_B2s"    # $30/month - cheapest viable
    node_count          = 1                  # Absolute minimum
    disk_size_gb        = 30                # Minimum allowed
    acr_sku             = "Basic"           # $5/month
    location            = "East US"         # Cheapest region
    load_balancer_sku   = "basic"          # Cheaper option
    network_plugin      = "kubenet"        # Free networking
    enable_monitoring   = false             # Disable to save money
    backup_retention    = 7                 # Minimum retention
  }
  
  estimated_costs = {
    aks_control_plane = 0      # FREE
    compute_node     = 30      # Standard_B2s
    storage          = 5       # 30GB managed disk
    load_balancer    = 0       # Basic LB included
    container_registry = 5     # Basic ACR
    total           = 40       # Under $45 budget
  }
}

# Cost validation check
resource "null_resource" "budget_check" {
  count = var.allow_overage ? 0 : 1
  
  triggers = {
    estimated_total = local.estimated_costs.total
    budget_limit   = var.budget_limit_usd
  }
  
  provisioner "local-exec" {
    command = local.estimated_costs.total > var.budget_limit_usd ? "echo 'ERROR: Estimated cost exceeds budget' && exit 1" : "echo 'Budget check passed'"
  }
}
