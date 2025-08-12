#!/bin/bash

# Azure AKS Video Streaming Platform Deployment Script
# Professional deployment with budget monitoring and cost optimization

set -e

# Configuration
RESOURCE_GROUP="video-streaming-dev-rg"
AKS_CLUSTER="video-streaming-dev-aks"
ACR_NAME="videostreamingdevacr8497"
NAMESPACE="video-streaming"

echo "🚀 Starting Azure AKS Video Streaming Platform Deployment"
echo "📊 Budget: $45 student account with monitoring enabled"
echo "🏷️  Cost Center: education (governance compliant)"
echo ""

# Function to check budget status
check_budget() {
    echo "💰 Checking current Azure spending..."
    az consumption usage list --output table 2>/dev/null || echo "⚠️  Budget monitoring: API may require additional permissions"
}

# Function to wait for AKS cluster
wait_for_aks() {
    echo "⏳ Waiting for AKS cluster to be ready..."
    while true; do
        STATUS=$(az aks show -g $RESOURCE_GROUP -n $AKS_CLUSTER --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
        
        if [ "$STATUS" = "Succeeded" ]; then
            echo "✅ AKS cluster is ready!"
            break
        elif [ "$STATUS" = "Failed" ]; then
            echo "❌ AKS cluster deployment failed!"
            az aks show -g $RESOURCE_GROUP -n $AKS_CLUSTER --output table
            exit 1
        else
            echo "⏳ AKS cluster status: $STATUS (waiting...)"
            sleep 30
        fi
    done
}

# Function to build and push Docker images
build_and_push_images() {
    echo "🐳 Building and pushing Docker images to ACR..."
    
    # Login to ACR
    echo "🔐 Logging into Azure Container Registry..."
    az acr login --name $ACR_NAME
    
    # Build backend image
    echo "🏗️  Building backend API image..."
    docker build -f docker/Dockerfile.backend -t $ACR_NAME.azurecr.io/backend-api:latest .
    
    # Build frontend image
    echo "🏗️  Building frontend image..."
    docker build -f docker/Dockerfile.frontend -t $ACR_NAME.azurecr.io/frontend:latest .
    
    # Push images
    echo "📤 Pushing images to ACR..."
    docker push $ACR_NAME.azurecr.io/backend-api:latest
    docker push $ACR_NAME.azurecr.io/frontend:latest
    
    echo "✅ Docker images built and pushed successfully!"
}

# Function to deploy to Kubernetes
deploy_to_kubernetes() {
    echo "☸️  Deploying to Kubernetes..."
    
    # Get AKS credentials
    echo "🔑 Getting AKS credentials..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing
    
    # Verify kubectl connection
    echo "🔍 Verifying Kubernetes connection..."
    kubectl cluster-info
    
    # Deploy applications
    echo "📦 Deploying applications to AKS..."
    kubectl apply -f k8s/azure/namespace.yaml
    kubectl apply -f k8s/azure/configmaps.yaml
    kubectl apply -f k8s/azure/redis.yaml
    kubectl apply -f k8s/azure/backend.yaml
    kubectl apply -f k8s/azure/frontend.yaml
    
    echo "⏳ Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/redis -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/backend-api -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/frontend -n $NAMESPACE
    
    echo "✅ All deployments are ready!"
}

# Function to get service information
get_service_info() {
    echo "🌐 Getting service information..."
    
    # Get external IP for frontend
    echo "⏳ Waiting for Load Balancer external IP..."
    for i in {1..20}; do
        EXTERNAL_IP=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
            echo "🎉 Video Streaming Platform is available at: http://$EXTERNAL_IP"
            break
        else
            echo "⏳ Waiting for external IP... (attempt $i/20)"
            sleep 15
        fi
    done
    
    if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
        echo "⚠️  External IP not assigned yet. Check later with:"
        echo "   kubectl get service frontend-service -n $NAMESPACE"
    fi
    
    # Show all services
    echo ""
    echo "📋 All services:"
    kubectl get services -n $NAMESPACE -o wide
    
    echo ""
    echo "📋 All pods:"
    kubectl get pods -n $NAMESPACE -o wide
}

# Function to show monitoring commands
show_monitoring() {
    echo ""
    echo "📊 Monitoring Commands:"
    echo "  Budget monitoring: az consumption usage list --output table"
    echo "  Resource costs: az billing usage list --output table"
    echo "  AKS status: kubectl get all -n $NAMESPACE"
    echo "  Pod logs: kubectl logs -f deployment/backend-api -n $NAMESPACE"
    echo "  Service status: kubectl get services -n $NAMESPACE"
    echo ""
    echo "🛠️  Troubleshooting:"
    echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
    echo "  kubectl logs <pod-name> -n $NAMESPACE"
    echo ""
    echo "💰 Cost Management:"
    echo "  - Basic Load Balancer (cost optimized)"
    echo "  - Standard_B2s VM (burstable, budget-friendly)"
    echo "  - Single node cluster (development optimized)"
    echo "  - Email alerts at 50%, 80%, 90% of $45 budget"
}

# Main execution
main() {
    check_budget
    echo ""
    
    # Check if AKS cluster exists and is ready
    if az aks show -g $RESOURCE_GROUP -n $AKS_CLUSTER >/dev/null 2>&1; then
        wait_for_aks
    else
        echo "❌ AKS cluster not found. Please ensure the cluster is created first."
        echo "   Run: az aks create -g $RESOURCE_GROUP -n $AKS_CLUSTER ..."
        exit 1
    fi
    
    build_and_push_images
    deploy_to_kubernetes
    get_service_info
    show_monitoring
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "💰 Remember: Monitor your spending at portal.azure.com"
    echo "📧 Email alerts configured for kolageneral@yahoo.com"
}

# Execute main function
main "$@"
