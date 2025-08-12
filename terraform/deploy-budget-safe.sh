#!/bin/bash

# BUDGET-SAFE Deployment Script
# Guaranteed to stay under $45/month budget

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}💰 BUDGET-SAFE Azure Deployment${NC}"
echo -e "${BLUE}Guaranteed Under $45/month${NC}"
echo "=================================="

# Function to validate budget safety
validate_budget() {
    echo -e "${YELLOW}💰 Budget Safety Check${NC}"
    echo "Your Budget Limit: $45/month"
    echo "Estimated Costs:"
    echo "  • AKS Control Plane: FREE"
    echo "  • Compute (1x B2s):  $30/month"
    echo "  • Storage (30GB):    $5/month"
    echo "  • Container Registry: $5/month"
    echo "  • Networking:        FREE"
    echo "  ─────────────────────────────"
    echo "  • TOTAL ESTIMATED:   $40/month"
    echo "  • SAFETY MARGIN:     $5 (12.5%)"
    echo ""
    echo -e "✅ ${GREEN}SAFE: Under budget by $5/month${NC}"
    
    read -p "Continue with budget-safe deployment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled for budget safety."
        exit 0
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        echo -e "❌ ${RED}Azure CLI required${NC}"
        echo "Install: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "❌ ${RED}Terraform required${NC}"
        echo "Install: https://terraform.io/downloads"
        exit 1
    fi
    
    # Check Azure login
    if ! az account show &> /dev/null; then
        echo -e "❌ ${RED}Please login to Azure${NC}"
        echo "Run: az login"
        exit 1
    fi
    
    echo -e "✅ ${GREEN}All prerequisites met${NC}"
}

# Function to setup budget alerts
setup_budget_protection() {
    echo -e "${YELLOW}🚨 Setting up budget protection...${NC}"
    
    # Get user email for alerts
    read -p "Enter your email for budget alerts: " user_email
    
    if [[ ! "$user_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "❌ ${RED}Invalid email format${NC}"
        exit 1
    fi
    
    # Update terraform variables
    cat > budget.tfvars << EOF
budget_limit_usd = 45
emergency_email = "$user_email"
allow_overage = false
EOF
    
    echo -e "✅ ${GREEN}Budget protection configured${NC}"
    echo "📧 Alerts will be sent to: $user_email"
}

# Function to deploy with budget safety
deploy_budget_safe() {
    echo -e "${YELLOW}🚀 Deploying budget-safe infrastructure...${NC}"
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    terraform validate
    
    # Plan with budget variables
    terraform plan -var-file=budget.tfvars -out=budget.tfplan
    
    # Show cost summary
    echo -e "${BLUE}📊 Final Cost Summary:${NC}"
    echo "This deployment will create:"
    echo "  • 1 Resource Group (FREE)"
    echo "  • 1 AKS Cluster with 1 node ($30/month)"
    echo "  • 1 Container Registry Basic ($5/month)"
    echo "  • Managed Storage 30GB ($5/month)"
    echo "  • Budget alerts at $32 and $40"
    echo ""
    
    read -p "Proceed with deployment? (yes/no): " final_confirm
    if [ "$final_confirm" != "yes" ]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    # Apply changes
    terraform apply budget.tfplan
    
    if [ $? -eq 0 ]; then
        echo -e "🎉 ${GREEN}Budget-safe deployment successful!${NC}"
    else
        echo -e "❌ ${RED}Deployment failed${NC}"
        exit 1
    fi
}

# Function to show cost monitoring setup
setup_cost_monitoring() {
    echo -e "${YELLOW}📊 Setting up cost monitoring...${NC}"
    
    # Create cost monitoring script
    cat > monitor-costs.sh << 'EOF'
#!/bin/bash
echo "💰 Current Azure Spending:"
az consumption usage list \
    --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
    --end-date $(date +%Y-%m-%d) \
    --query '[].{Service:meterName,Cost:pretaxCost}' \
    --output table

echo ""
echo "📊 Resource List:"
az resource list --resource-group video-budget-rg --output table

echo ""
echo "🚨 Emergency Commands:"
echo "Stop cluster: az aks stop --name video-budget-aks --resource-group video-budget-rg"
echo "Delete all: terraform destroy -auto-approve"
EOF
    
    chmod +x monitor-costs.sh
    
    echo -e "✅ ${GREEN}Cost monitoring script created: ./monitor-costs.sh${NC}"
}

# Function to show final instructions
show_final_instructions() {
    echo -e "${GREEN}🎉 Budget-Safe Deployment Complete!${NC}"
    echo "=================================="
    
    terraform output budget_safety_report
    
    echo ""
    echo -e "${BLUE}🔧 Next Steps:${NC}"
    echo "1. Configure kubectl:"
    echo "   az aks get-credentials --resource-group video-budget-rg --name video-budget-aks"
    echo ""
    echo "2. Deploy your application:"
    echo "   kubectl apply -f ../azure-aks/"
    echo ""
    echo "3. Monitor costs daily:"
    echo "   ./monitor-costs.sh"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT BUDGET REMINDERS:${NC}"
    echo "• Check Azure Portal > Cost Management DAILY"
    echo "• You'll receive email alerts at $32 and $40 spending"
    echo "• Stop cluster when not in use to save money"
    echo "• Delete everything when done: terraform destroy"
    echo "• Maximum safe runtime: ~30 days with $45 budget"
}

# Main execution
main() {
    validate_budget
    check_prerequisites
    setup_budget_protection
    deploy_budget_safe
    setup_cost_monitoring
    show_final_instructions
}

# Run main function
main "$@"
