#!/bin/bash

# Quick validation script for AKS deployment

echo "🔍 Validating AKS Deployment"
echo "============================"

# Check if kubectl is connected
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl not connected to cluster"
    echo "Run: az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks"
    exit 1
fi

echo "✅ kubectl connected to cluster"

# Check namespace
if kubectl get namespace video-streaming &> /dev/null; then
    echo "✅ Namespace 'video-streaming' exists"
else
    echo "❌ Namespace 'video-streaming' not found"
fi

# Check pods status
echo ""
echo "📦 Pod Status:"
kubectl get pods -n video-streaming

# Check services
echo ""
echo "🌐 Services:"
kubectl get svc -n video-streaming

# Check persistent volumes
echo ""
echo "💾 Storage:"
kubectl get pvc -n video-streaming

# Check if external IP is assigned
EXTERNAL_IP=$(kubectl get svc frontend-service -n video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
    echo ""
    echo "🎉 Deployment Successful!"
    echo "🌐 Frontend URL: http://$EXTERNAL_IP"
    echo "🔗 API URL: http://$EXTERNAL_IP/api"
    echo ""
    echo "🧪 Test the application:"
    echo "curl -s http://$EXTERNAL_IP/api/health"
else
    echo ""
    echo "⏳ External IP not yet assigned"
    echo "💡 Run: kubectl get svc frontend-service -n video-streaming --watch"
fi

# Resource usage
echo ""
echo "📊 Resource Usage:"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
kubectl top pods -n video-streaming 2>/dev/null || echo "Pod metrics not available"
