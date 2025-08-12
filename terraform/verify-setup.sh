#!/bin/bash

# Quick setup verification script for Terraform deployment

echo "🔍 Terraform Deployment Setup Verification"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

READY=true

echo -e "${BLUE}📧 Contact Information:${NC}"
echo "Email for alerts: kolageneral@yahoo.com ✅"
echo "Budget limit: $45/month ✅"
echo "Alert thresholds: 50%, 80%, 90% ✅"
echo ""

echo -e "${BLUE}🔧 Checking Software Requirements:${NC}"

# Check Terraform
if command -v terraform &> /dev/null; then
    VERSION=$(terraform --version | head -n1 | cut -d'v' -f2)
    echo -e "✅ ${GREEN}Terraform v$VERSION installed${NC}"
else
    echo -e "❌ ${RED}Terraform not found${NC}"
    echo -e "   ${YELLOW}Install from: https://terraform.io/downloads${NC}"
    READY=false
fi

# Check Azure CLI
if command -v az &> /dev/null; then
    VERSION=$(az --version | grep azure-cli | cut -d' ' -f2)
    echo -e "✅ ${GREEN}Azure CLI $VERSION installed${NC}"
else
    echo -e "❌ ${RED}Azure CLI not found${NC}"
    echo -e "   ${YELLOW}Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli${NC}"
    READY=false
fi

# Check Docker
if command -v docker &> /dev/null; then
    VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo -e "✅ ${GREEN}Docker $VERSION installed${NC}"
    
    # Check if Docker is running
    if docker info &> /dev/null; then
        echo -e "✅ ${GREEN}Docker daemon is running${NC}"
    else
        echo -e "❌ ${RED}Docker daemon not running${NC}"
        echo -e "   ${YELLOW}Start Docker Desktop${NC}"
        READY=false
    fi
else
    echo -e "❌ ${RED}Docker not found${NC}"
    echo -e "   ${YELLOW}Install Docker Desktop from docker.com${NC}"
    READY=false
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
    echo -e "✅ ${GREEN}kubectl $VERSION installed${NC}"
else
    echo -e "❌ ${RED}kubectl not found${NC}"
    echo -e "   ${YELLOW}Install with: az aks install-cli${NC}"
    READY=false
fi

echo ""
echo -e "${BLUE}🔐 Checking Azure Authentication:${NC}"

# Check Azure login
if az account show &> /dev/null; then
    ACCOUNT=$(az account show --query user.name -o tsv)
    SUBSCRIPTION=$(az account show --query name -o tsv)
    echo -e "✅ ${GREEN}Logged in as: $ACCOUNT${NC}"
    echo -e "✅ ${GREEN}Subscription: $SUBSCRIPTION${NC}"
    
    # Check credits (if possible)
    echo -e "💰 ${YELLOW}Checking Azure credits...${NC}"
    CREDITS=$(az consumption budget list --query '[0].amount' -o tsv 2>/dev/null || echo "Unknown")
    if [ "$CREDITS" != "Unknown" ] && [ -n "$CREDITS" ]; then
        echo -e "💳 Available credits: $${CREDITS}"
    else
        echo -e "💳 ${YELLOW}Please verify you have at least $45 in Azure credits${NC}"
    fi
else
    echo -e "❌ ${RED}Not logged in to Azure${NC}"
    echo -e "   ${YELLOW}Run: az login${NC}"
    READY=false
fi

echo ""
echo -e "${BLUE}📁 Checking File Structure:${NC}"

# Check if we're in the right directory
if [ -f "main.tf" ] && [ -f "variables.tf" ] && [ -f "terraform.tfvars" ]; then
    echo -e "✅ ${GREEN}Terraform files found${NC}"
else
    echo -e "❌ ${RED}Terraform files not found${NC}"
    echo -e "   ${YELLOW}Navigate to: cloud-video-network-monitoring/terraform/${NC}"
    READY=false
fi

echo ""
echo -e "${BLUE}💰 Estimated Deployment Costs:${NC}"
echo "• AKS Control Plane: FREE"
echo "• Compute (1x B2s): ~$30/month"
echo "• Storage (30GB): ~$5/month" 
echo "• Load Balancer: ~$5/month"
echo "• Container Registry: ~$5/month"
echo "• Total: ~$45/month (within budget)"

echo ""
echo -e "${BLUE}📧 Configured Alerts:${NC}"
echo "• 50% threshold ($22.50) → kolageneral@yahoo.com"
echo "• 80% threshold ($36.00) → kolageneral@yahoo.com"
echo "• 90% threshold ($40.50) → kolageneral@yahoo.com"

echo ""
if [ "$READY" = true ]; then
    echo -e "🎉 ${GREEN}READY FOR DEPLOYMENT!${NC}"
    echo ""
    echo -e "${BLUE}🚀 To deploy your infrastructure:${NC}"
    echo "1. terraform init"
    echo "2. terraform plan"
    echo "3. terraform apply"
    echo ""
    echo -e "Or use the automated script:"
    echo "./deploy.sh"
    echo ""
    echo -e "${YELLOW}⏱️  Estimated deployment time: 10-15 minutes${NC}"
else
    echo -e "⚠️  ${RED}PLEASE FIX THE ISSUES ABOVE BEFORE DEPLOYING${NC}"
    echo ""
    echo -e "${BLUE}Quick Fix Commands:${NC}"
    echo "• Install Terraform: Download from terraform.io"
    echo "• Install Azure CLI: Download from Microsoft docs"
    echo "• Install Docker: Download Docker Desktop"
    echo "• Login to Azure: az login"
    echo "• Start Docker: Open Docker Desktop"
fi

echo ""
echo -e "${BLUE}🆘 Emergency Commands (if needed):${NC}"
echo "• Check costs: az consumption usage list"
echo "• Stop everything: terraform destroy"
echo "• Emergency cleanup: az group delete --name video-streaming-dev-rg"
