#!/bin/bash

# Azure AKS Deployment Script for Video Streaming Platform
# Budget-optimized for Azure Student Account ($45)

set -e

# Configuration
RESOURCE_GROUP="video-streaming-rg"
AKS_CLUSTER_NAME="video-streaming-aks"
LOCATION="East US"  # Cheapest region
ACR_NAME="videostreamingacr$(date +%s)"  # Unique ACR name
NODE_COUNT=1  # Minimal for cost optimization
VM_SIZE="Standard_B2s"  # 2 vCPU, 4GB RAM - Budget friendly

echo "🚀 Starting Azure AKS Deployment for Video Streaming Platform"
echo "💰 Budget-optimized for Azure Student Account"
echo "=================================================="

# Step 1: Create Resource Group
echo "📦 Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location "$LOCATION"

# Step 2: Create Azure Container Registry (ACR)
echo "🐳 Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --location "$LOCATION"

# Step 3: Create AKS Cluster (Budget Optimized)
echo "☸️  Creating AKS Cluster (Budget Optimized)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $VM_SIZE \
    --location "$LOCATION" \
    --attach-acr $ACR_NAME \
    --enable-managed-identity \
    --generate-ssh-keys \
    --tier free \
    --network-plugin azure

# Step 4: Get AKS Credentials
echo "🔑 Getting AKS Credentials..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME

# Step 5: Build and Push Images to ACR
echo "🏗️  Building and Pushing Images to ACR..."

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push backend image
echo "Building backend image..."
cd ../
docker build -t $ACR_LOGIN_SERVER/video-backend:latest -f backend/Dockerfile .
docker push $ACR_LOGIN_SERVER/video-backend:latest

# Build and push frontend image
echo "Building frontend image..."
docker build -t $ACR_LOGIN_SERVER/video-frontend:latest -f frontend/Dockerfile .
docker push $ACR_LOGIN_SERVER/video-frontend:latest

cd azure-aks/

# Step 6: Update Kubernetes manifests with ACR URL
echo "📝 Updating Kubernetes manifests..."
sed -i "s/YOUR_ACR_REGISTRY\.azurecr\.io/$ACR_LOGIN_SERVER/g" 4-backend.yaml
sed -i "s/YOUR_ACR_REGISTRY\.azurecr\.io/$ACR_LOGIN_SERVER/g" 5-frontend.yaml

# Step 7: Deploy to AKS
echo "🚀 Deploying to AKS..."
kubectl apply -f 1-namespace.yaml
kubectl apply -f 2-postgres.yaml
kubectl apply -f 3-redis.yaml

# Wait for database to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n video-streaming --timeout=300s

kubectl apply -f 4-backend.yaml
kubectl apply -f 5-frontend.yaml

# Step 8: Get External IP
echo "🌐 Getting External IP..."
echo "Waiting for LoadBalancer IP assignment..."
kubectl get svc frontend-service -n video-streaming --watch

echo ""
echo "✅ Deployment Complete!"
echo "=================================================="
echo "📊 Cost Breakdown (Estimated Monthly):"
echo "   • AKS Control Plane: FREE"
echo "   • B2s Node (2vCPU, 4GB): ~$30-35"
echo "   • Storage (30GB SSD): ~$5-8"
echo "   • Load Balancer: ~$5"
echo "   • Total: ~$40-48/month"
echo ""
echo "🔗 Access your application:"
echo "   Frontend: http://[EXTERNAL-IP]"
echo "   Backend API: http://[EXTERNAL-IP]/api"
echo ""
echo "📝 To get the external IP later:"
echo "   kubectl get svc frontend-service -n video-streaming"
echo ""
echo "🧹 To clean up and save costs:"
echo "   az group delete --name $RESOURCE_GROUP --yes --no-wait"
