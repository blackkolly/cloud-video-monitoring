# Development environment configuration
environment = "dev"
location    = "East US"
owner       = "student"
cost_center = "education"

# AKS Configuration - Budget optimized
kubernetes_version = "1.27"
node_count        = 1
vm_size           = "Standard_B2s"  # 2 vCPU, 4GB RAM - $30-35/month
disk_size_gb      = 30

# Network Configuration
vnet_cidr       = "10.0.0.0/16"
aks_subnet_cidr = "10.0.1.0/24"

# Container Registry
acr_sku = "Basic"  # $5/month

# Database Configuration - Budget optimized
postgres_version    = "15"
postgres_sku        = "B_Standard_B1ms"  # Burstable, 1 vCore, 2GB RAM
postgres_storage_gb = 32  # Minimum for flexible server

# Monitoring
enable_monitoring    = true
log_retention_days   = 30

# Security
enable_rbac           = true
enable_private_cluster = false  # Simpler for student account

# Budget Control
max_monthly_cost_usd         = 45
alert_threshold_percentage   = 80  # Main alert at 80% ($36)
# Additional alerts configured: 50% ($22.50) and 90% ($40.50)
