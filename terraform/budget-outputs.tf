# Budget-safe outputs with cost breakdown

output "budget_safety_report" {
  description = "Budget safety and cost breakdown"
  value = {
    estimated_monthly_cost = {
      aks_control_plane     = "$0 (FREE)"
      compute_standard_b2s  = "$30/month"
      storage_30gb         = "$5/month"
      container_registry   = "$5/month"
      networking           = "$0 (included)"
      total_estimated      = "$40/month"
    }
    
    budget_status = {
      your_budget_limit    = "$${var.budget_limit_usd}"
      estimated_usage      = "$40"
      remaining_budget     = "$${var.budget_limit_usd - 40}"
      safety_margin        = "12.5%"
      status              = var.budget_limit_usd >= 40 ? "✅ SAFE" : "❌ OVER BUDGET"
    }
    
    cost_controls = {
      budget_alerts_at     = ["$32 (80%)", "$40 (100%)"]
      auto_shutdown        = "Manual (scripts provided)"
      monitoring          = "Budget alerts enabled"
      emergency_contact   = var.emergency_email
    }
  }
}

output "resource_info" {
  description = "Deployed resource information"
  value = {
    resource_group      = azurerm_resource_group.main.name
    aks_cluster        = azurerm_kubernetes_cluster.main.name
    container_registry = azurerm_container_registry.main.login_server
    location           = azurerm_resource_group.main.location
  }
}

output "cost_optimization_commands" {
  description = "Commands to manage costs"
  value = {
    stop_cluster       = "az aks stop --name ${azurerm_kubernetes_cluster.main.name} --resource-group ${azurerm_resource_group.main.name}"
    start_cluster      = "az aks start --name ${azurerm_kubernetes_cluster.main.name} --resource-group ${azurerm_resource_group.main.name}"
    check_costs        = "az consumption usage list --start-date $(date +%Y-%m-01) --end-date $(date +%Y-%m-%d)"
    emergency_cleanup  = "terraform destroy -auto-approve"
  }
}

output "setup_commands" {
  description = "Commands to complete setup"
  value = {
    get_credentials = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
    acr_login      = "az acr login --name ${azurerm_container_registry.main.name}"
    deploy_app     = "kubectl apply -f ../azure-aks/"
  }
}

output "budget_warnings" {
  description = "Important budget warnings"
  value = [
    "🚨 MONITOR COSTS DAILY in Azure Portal",
    "📧 VERIFY budget alert email: ${var.emergency_email}",
    "⏹️  STOP cluster when not in use to save money",
    "🧹 DELETE resources when done: terraform destroy",
    "📊 CHECK spending: Azure Portal > Cost Management",
    "⚠️  MAXIMUM SAFE RUNTIME: ~30 days with $45 budget"
  ]
}
