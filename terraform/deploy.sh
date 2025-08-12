#!/bin/bash

# Professional Terraform deployment script
# Follows enterprise best practices and safety checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏢 Professional Terraform Deployment${NC}"
echo -e "${BLUE}Azure AKS Video Streaming Platform${NC}"
echo "=============================================="

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    local checks_passed=0
    local total_checks=4
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        echo -e "✅ ${GREEN}Terraform found${NC}"
        checks_passed=$((checks_passed + 1))
    else
        echo -e "❌ ${RED}Terraform not found${NC}"
        echo -e "   Install from: https://terraform.io/downloads"
    fi
    
    # Check Azure CLI
    if command -v az &> /dev/null; then
        echo -e "✅ ${GREEN}Azure CLI found${NC}"
        checks_passed=$((checks_passed + 1))
    else
        echo -e "❌ ${RED}Azure CLI not found${NC}"
        echo -e "   Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo -e "✅ ${GREEN}Docker found${NC}"
        checks_passed=$((checks_passed + 1))
    else
        echo -e "❌ ${RED}Docker not found${NC}"
        echo -e "   Install Docker Desktop"
    fi
    
    # Check Azure login
    if az account show &> /dev/null; then
        echo -e "✅ ${GREEN}Azure CLI authenticated${NC}"
        checks_passed=$((checks_passed + 1))
    else
        echo -e "❌ ${RED}Azure CLI not authenticated${NC}"
        echo -e "   Run: az login"
    fi
    
    if [ $checks_passed -eq $total_checks ]; then
        echo -e "🎉 ${GREEN}All prerequisites met!${NC}"
        return 0
    else
        echo -e "⚠️  ${RED}Please fix the issues above before proceeding${NC}"
        return 1
    fi
}

# Function to validate Terraform configuration
validate_terraform() {
    echo -e "${YELLOW}📝 Validating Terraform configuration...${NC}"
    
    terraform fmt -check=true -diff=true
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Formatting issues found. Auto-fixing...${NC}"
        terraform fmt
    fi
    
    terraform validate
    if [ $? -eq 0 ]; then
        echo -e "✅ ${GREEN}Terraform configuration is valid${NC}"
    else
        echo -e "❌ ${RED}Terraform configuration has errors${NC}"
        exit 1
    fi
}

# Function to show cost estimate
show_cost_estimate() {
    echo -e "${BLUE}💰 Estimated Monthly Costs:${NC}"
    echo "================================"
    echo "• AKS Control Plane:     FREE"
    echo "• Compute (Standard_B2s): $30-35"
    echo "• Storage (30GB):        $5-8"
    echo "• Load Balancer:         $5"
    echo "• Container Registry:    $5"
    echo "• PostgreSQL (Basic):    $10-15"
    echo "• Monitoring:            $2-5"
    echo "--------------------------------"
    echo "• Total Estimated:       $57-73/month"
    echo "• Your Budget Limit:     $45/month"
    echo ""
    echo -e "${YELLOW}⚠️  Estimated cost exceeds budget!${NC}"
    echo -e "${YELLOW}Consider scaling down or using spot instances${NC}"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}🚀 Deploying infrastructure...${NC}"
    
    # Initialize Terraform
    echo "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    echo "Creating deployment plan..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo ""
    echo -e "${YELLOW}📋 Deployment Plan Summary:${NC}"
    terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[] | contains("create")) | .address' | wc -l | xargs echo "Resources to create:"
    echo ""
    
    read -p "Do you want to proceed with deployment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    # Apply changes
    echo "Applying changes..."
    terraform apply tfplan
    
    if [ $? -eq 0 ]; then
        echo -e "🎉 ${GREEN}Infrastructure deployed successfully!${NC}"
    else
        echo -e "❌ ${RED}Deployment failed${NC}"
        exit 1
    fi
}

# Function to configure kubectl
configure_kubectl() {
    echo -e "${YELLOW}🔧 Configuring kubectl...${NC}"
    
    # Get resource group and cluster name from Terraform output
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    
    # Configure kubectl
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
    
    if [ $? -eq 0 ]; then
        echo -e "✅ ${GREEN}kubectl configured successfully${NC}"
        
        # Test cluster connection
        echo "Testing cluster connection..."
        kubectl cluster-info
    else
        echo -e "❌ ${RED}Failed to configure kubectl${NC}"
        exit 1
    fi
}

# Function to build and push container images
build_and_push_images() {
    echo -e "${YELLOW}🐳 Building and pushing container images...${NC}"
    
    # Get ACR details from Terraform output
    ACR_NAME=$(terraform output -raw container_registry_name)
    ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
    
    # Login to ACR
    az acr login --name "$ACR_NAME"
    
    # Build and push backend image
    echo "Building backend image..."
    cd ../
    docker build -t "$ACR_LOGIN_SERVER/video-backend:latest" -f backend/Dockerfile . --platform linux/amd64
    docker push "$ACR_LOGIN_SERVER/video-backend:latest"
    
    # Build and push frontend image
    echo "Building frontend image..."
    docker build -t "$ACR_LOGIN_SERVER/video-frontend:latest" -f frontend/Dockerfile . --platform linux/amd64
    docker push "$ACR_LOGIN_SERVER/video-frontend:latest"
    
    cd terraform/
    
    echo -e "✅ ${GREEN}Images built and pushed successfully${NC}"
}

# Function to deploy Kubernetes resources
deploy_kubernetes() {
    echo -e "${YELLOW}☸️  Deploying Kubernetes resources...${NC}"
    
    # Update manifests with ACR URL
    ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
    
    # Create temporary manifests with correct ACR URL
    sed "s/YOUR_ACR_REGISTRY\.azurecr\.io/$ACR_LOGIN_SERVER/g" ../azure-aks/4-backend.yaml > k8s-backend.yaml
    sed "s/YOUR_ACR_REGISTRY\.azurecr\.io/$ACR_LOGIN_SERVER/g" ../azure-aks/5-frontend.yaml > k8s-frontend.yaml
    
    # Deploy Kubernetes resources
    kubectl apply -f ../azure-aks/1-namespace.yaml
    kubectl apply -f ../azure-aks/2-postgres.yaml
    kubectl apply -f ../azure-aks/3-redis.yaml
    
    # Wait for database
    echo "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n video-streaming --timeout=300s || true
    
    kubectl apply -f k8s-backend.yaml
    kubectl apply -f k8s-frontend.yaml
    
    # Clean up temporary files
    rm -f k8s-backend.yaml k8s-frontend.yaml
    
    echo -e "✅ ${GREEN}Kubernetes resources deployed${NC}"
}

# Function to show deployment results
show_results() {
    echo -e "${GREEN}🎉 Deployment Complete!${NC}"
    echo "=============================================="
    
    # Show Terraform outputs
    terraform output
    
    echo ""
    echo -e "${BLUE}📱 Next Steps:${NC}"
    echo "1. Wait for external IP: kubectl get svc frontend-service -n video-streaming --watch"
    echo "2. Access your application: http://[EXTERNAL-IP]"
    echo "3. Monitor costs in Azure Portal"
    echo "4. Set up budget alerts"
    
    echo ""
    echo -e "${BLUE}🧹 To clean up when done:${NC}"
    echo "terraform destroy -auto-approve"
}

# Main execution
main() {
    # Check if we're in the terraform directory
    if [ ! -f "main.tf" ]; then
        echo -e "${RED}❌ Please run this script from the terraform directory${NC}"
        exit 1
    fi
    
    # Run all steps
    check_prerequisites || exit 1
    validate_terraform
    show_cost_estimate
    deploy_infrastructure
    configure_kubectl
    build_and_push_images
    deploy_kubernetes
    show_results
}

# Run main function
main "$@"
