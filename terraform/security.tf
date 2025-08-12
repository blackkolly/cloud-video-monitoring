# Azure Key Vault for secure secret management
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  # Enable for deployment access
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  
  # Soft delete for production safety
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Set to true for production
  
  tags = local.common_tags

  # Network access rules
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
    
    # For production, restrict access
    # ip_rules = ["your-office-ip/32"]
    # virtual_network_subnet_ids = [azurerm_subnet.aks.id]
  }
}

# Key Vault access policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create", "Delete", "Get", "List", "Update", "Import", "Backup", "Restore"
  ]

  secret_permissions = [
    "Set", "Get", "Delete", "List", "Purge", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Create", "Delete", "Get", "List", "Update", "Import"
  ]
}

# Key Vault access policy for AKS
resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id

  secret_permissions = [
    "Get", "List"
  ]

  depends_on = [azurerm_kubernetes_cluster.main]
}

# PostgreSQL database password
resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

# Store database password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${local.project_name}-${local.environment}-postgres"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = var.postgres_version
  administrator_login    = "videoadmin"
  administrator_password = random_password.postgres_password.result
  
  # Budget-optimized configuration
  sku_name = var.postgres_sku
  storage_mb = var.postgres_storage_gb * 1024
  
  # Backup configuration
  backup_retention_days = 7
  
  # High availability disabled for cost optimization - remove the block entirely
  
  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# PostgreSQL database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "video_monitoring_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL firewall rule to allow Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL firewall rule for AKS subnet
resource "azurerm_postgresql_flexible_server_firewall_rule" "aks_subnet" {
  name             = "AllowAKSSubnet"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = cidrhost(var.aks_subnet_cidr, 0)
  end_ip_address   = cidrhost(var.aks_subnet_cidr, -1)
}
