# Budget monitoring and cost management

# Budget for cost control
resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "${local.project_name}-${local.environment}-budget"
  resource_group_id = azurerm_resource_group.main.id

  amount     = var.max_monthly_cost_usd
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h")) # 1 year
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_resource_group.main.name,
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 50
    operator  = "GreaterThan"

    contact_emails = [
      "kolageneral@yahoo.com",
    ]
  }

  notification {
    enabled   = true
    threshold = var.alert_threshold_percentage
    operator  = "GreaterThan"

    contact_emails = [
      "kolageneral@yahoo.com",
    ]
  }

  notification {
    enabled   = true
    threshold = 90
    operator  = "GreaterThan"

    contact_emails = [
      "kolageneral@yahoo.com",
    ]
  }
}

# Action group for budget alerts
resource "azurerm_monitor_action_group" "budget_alerts" {
  name                = "${local.project_name}-${local.environment}-budget-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "budgetalert"
  tags                = local.common_tags

  email_receiver {
    name          = "budget-alert"
    email_address = "kolageneral@yahoo.com"
  }

  # SMS alerts disabled due to phone number requirement
  # To enable SMS: replace with your valid phone number
  # sms_receiver {
  #   name         = "budget-sms"
  #   country_code = "1"
  #   phone_number = "your-phone-number"
  # }
}

# Cost monitoring is handled by budget alerts above
# Simplified monitoring for student budget compliance

# Output useful monitoring information
output "monitoring_dashboard_url" {
  description = "URL to view costs and monitoring in Azure Portal"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_resource_group.main.id}/overview"
}

# Resource tagging policy for cost tracking
resource "azurerm_policy_definition" "require_cost_center_tag" {
  name         = "${local.project_name}-require-cost-center-tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Cost Center Tag"
  description  = "Requires resources to have a cost center tag for billing"

  policy_rule = jsonencode({
    if = {
      field = "tags['CostCenter']"
      exists = "false"
    }
    then = {
      effect = "deny"
    }
  })

  parameters = jsonencode({})
}

# Assign the policy to the resource group
resource "azurerm_resource_group_policy_assignment" "cost_center_tag" {
  name                 = "${local.project_name}-cost-center-tag-assignment"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.require_cost_center_tag.id
  display_name         = "Require Cost Center Tag Assignment"
  description          = "Ensures all resources have cost center tags"
}
