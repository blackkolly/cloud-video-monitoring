# Professional Terraform Outputs
# Provides important information after deployment

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_cluster_portal_fqdn" {
  description = "Portal FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
  sensitive   = false
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "acr_login_command" {
  description = "Command to login to Azure Container Registry"
  value       = "az acr login --name ${azurerm_container_registry.main.name}"
}

output "frontend_url" {
  description = "Frontend application URL (available after Kubernetes deployment)"
  value       = "Check: kubectl get svc frontend-service -n video-streaming"
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    aks_control_plane = "FREE"
    compute_nodes     = "$30-35 (${var.vm_size})"
    storage          = "$5-8 (managed disks)"
    networking       = "$5 (load balancer)"
    container_registry = "$5 (${var.acr_sku} tier)"
    database         = "$10-15 (${var.postgres_sku})"
    monitoring       = "$2-5 (Log Analytics)"
    total_estimated  = "$57-73/month"
    budget_limit     = "$${var.max_monthly_cost_usd}"
    budget_alerts    = "50% ($22.50), 80% ($36), 90% ($40.50)"
    contact_email    = "kolageneral@yahoo.com"
  }
}

output "cost_optimization_tips" {
  description = "Tips to reduce costs"
  value = [
    "Scale down AKS nodes when not in use: az aks scale --node-count 0",
    "Use Azure Dev/Test pricing for eligible resources",
    "Set up budget alerts in Azure Portal",
    "Delete unused storage and snapshots",
    "Use spot instances for non-production workloads"
  ]
}

output "management_commands" {
  description = "Useful management commands"
  value = {
    view_resources     = "az resource list --resource-group ${azurerm_resource_group.main.name} --output table"
    aks_nodes         = "kubectl get nodes"
    aks_pods          = "kubectl get pods --all-namespaces"
    cost_analysis     = "az consumption usage list --start-date $(date +%Y-%m-01) --end-date $(date +%Y-%m-%d)"
    cleanup_all       = "terraform destroy -auto-approve"
  }
}

output "security_notes" {
  description = "Important security information"
  value = [
    "Database credentials are stored in Key Vault",
    "AKS uses managed identity for ACR access",
    "Network security groups restrict access",
    "Enable Azure Defender for additional security",
    "Regularly update Kubernetes version"
  ]
}
