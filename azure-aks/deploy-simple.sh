#!/bin/bash

# Direct Azure AKS Deployment - No Terraform Required
# Budget-optimized for Azure Student Account ($45)

set -e

# Configuration
RESOURCE_GROUP="video-streaming-rg"
AKS_CLUSTER_NAME="video-streaming-aks"
LOCATION="East US"  # Cheapest region
ACR_NAME="videoacr$(date +%s | tail -c 6)"  # Short unique name
NODE_COUNT=1
VM_SIZE="Standard_B2s"  # 2 vCPU, 4GB RAM - Budget friendly

echo "🚀 Direct Azure AKS Deployment (No Terraform)"
echo "💰 Budget: ~$40-45/month for Azure Student Account"
echo "=================================================="

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Install it first:"
    echo "   az aks install-cli"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Install Docker Desktop first"
    exit 1
fi

echo "✅ All prerequisites found"

# Login check
echo "🔐 Checking Azure login..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "✅ Using subscription: $SUBSCRIPTION_ID"

# Step 1: Create Resource Group
echo ""
echo "📦 Step 1: Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location "$LOCATION" \
    --output table

# Step 2: Create Azure Container Registry
echo ""
echo "🐳 Step 2: Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true \
    --location "$LOCATION" \
    --output table

# Get ACR details
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)
echo "✅ ACR created: $ACR_LOGIN_SERVER"

# Step 3: Create AKS Cluster
echo ""
echo "☸️  Step 3: Creating AKS Cluster (This takes 5-10 minutes)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $VM_SIZE \
    --location "$LOCATION" \
    --attach-acr $ACR_NAME \
    --enable-managed-identity \
    --generate-ssh-keys \
    --network-plugin kubenet \
    --output table

echo "✅ AKS Cluster created successfully!"

# Step 4: Get credentials
echo ""
echo "🔑 Step 4: Getting AKS credentials..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --overwrite-existing

echo "✅ kubectl configured for your cluster"

# Step 5: Build and push Docker images
echo ""
echo "🏗️  Step 5: Building and pushing Docker images..."

# Login to ACR
az acr login --name $ACR_NAME

# Build backend image
echo "Building backend image..."
cd ../
docker build -t $ACR_LOGIN_SERVER/video-backend:latest -f backend/Dockerfile . --platform linux/amd64

# Build frontend image  
echo "Building frontend image..."
docker build -t $ACR_LOGIN_SERVER/video-frontend:latest -f frontend/Dockerfile . --platform linux/amd64

# Push images
echo "Pushing images to ACR..."
docker push $ACR_LOGIN_SERVER/video-backend:latest
docker push $ACR_LOGIN_SERVER/video-frontend:latest

cd azure-aks/

echo "✅ Images pushed to ACR successfully!"

# Step 6: Update manifests with ACR URL
echo ""
echo "📝 Step 6: Updating Kubernetes manifests..."
# Create temporary files with updated ACR URL
sed "s/YOUR_ACR_REGISTRY\.azurecr\.io/$ACR_LOGIN_SERVER/g" 4-backend.yaml > 4-backend-updated.yaml
sed "s/YOUR_ACR_REGISTRY\.azurecr\.io/$ACR_LOGIN_SERVER/g" 5-frontend.yaml > 5-frontend-updated.yaml

echo "✅ Manifests updated with ACR URL"

# Step 7: Deploy to Kubernetes
echo ""
echo "🚀 Step 7: Deploying to Kubernetes..."

echo "Creating namespace and configs..."
kubectl apply -f 1-namespace.yaml

echo "Deploying PostgreSQL..."
kubectl apply -f 2-postgres.yaml

echo "Deploying Redis..."
kubectl apply -f 3-redis.yaml

echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n video-streaming --timeout=300s || echo "⚠️  Timeout waiting for PostgreSQL (continuing anyway)"

echo "Deploying backend API..."
kubectl apply -f 4-backend-updated.yaml

echo "Deploying frontend..."
kubectl apply -f 5-frontend-updated.yaml

# Clean up temporary files
rm -f 4-backend-updated.yaml 5-frontend-updated.yaml

echo "✅ All services deployed!"

# Step 8: Wait for external IP
echo ""
echo "🌐 Step 8: Waiting for LoadBalancer IP assignment..."
echo "This may take 2-5 minutes..."

# Wait for external IP (with timeout)
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    EXTERNAL_IP=$(kubectl get svc frontend-service -n video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        break
    fi
    echo "⏳ Waiting for external IP... ($elapsed/$timeout seconds)"
    sleep 10
    elapsed=$((elapsed + 10))
done

# Display results
echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=================================================="

if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
    echo "✅ Your video streaming platform is ready!"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Frontend: http://$EXTERNAL_IP"
    echo "   Backend API: http://$EXTERNAL_IP/api"
    echo "   Health Check: http://$EXTERNAL_IP/api/health"
    echo ""
    echo "🧪 Quick Test:"
    echo "   curl http://$EXTERNAL_IP/api/health"
else
    echo "⏳ External IP not yet assigned. Check status with:"
    echo "   kubectl get svc frontend-service -n video-streaming"
fi

echo ""
echo "📊 Cost Breakdown (Estimated Monthly):"
echo "   • AKS Control Plane: FREE"
echo "   • Standard_B2s Node: ~$30-35"
echo "   • Storage (30GB): ~$5-8"
echo "   • Load Balancer: ~$5"
echo "   • Container Registry: ~$5"
echo "   • Total: ~$45-53/month"

echo ""
echo "📋 Management Commands:"
echo "   Check pods: kubectl get pods -n video-streaming"
echo "   Check services: kubectl get svc -n video-streaming"
echo "   View logs: kubectl logs -l app=backend-api -n video-streaming"
echo "   Scale down: kubectl scale deployment backend-api --replicas=1 -n video-streaming"

echo ""
echo "🧹 To delete everything and stop charges:"
echo "   az group delete --name $RESOURCE_GROUP --yes --no-wait"

echo ""
echo "🎯 Next Steps:"
echo "1. Test video upload functionality"
echo "2. Configure domain name (optional)"
echo "3. Set up budget alerts in Azure Portal"
echo "4. Monitor costs daily"
