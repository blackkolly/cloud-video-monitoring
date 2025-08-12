#!/bin/bash

# 🚨 Grafana Troubleshooting & Recovery Script
# Fix for terminal and Grafana connectivity issues

echo "🚨 Grafana Emergency Troubleshooting Guide"
echo "=========================================="
echo "Current Date: $(date)"
echo

# Function to print section headers
print_section() {
    echo
    echo "🎯 $1"
    echo "$(echo "$1" | sed 's/./=/g')"
}

# Function to check command availability
check_command() {
    if command -v $1 >/dev/null 2>&1; then
        echo "✅ $1 is available"
        return 0
    else
        echo "❌ $1 is not available"
        return 1
    fi
}

print_section "STEP 1: System Check"
echo "🔍 Checking system tools..."
check_command kubectl
check_command az
check_command docker
check_command curl

print_section "STEP 2: Azure & Kubernetes Connectivity"

echo "🔗 Testing Azure CLI connection..."
az account show --output table 2>/dev/null || echo "❌ Azure CLI not authenticated"

echo
echo "🔗 Testing Kubernetes connection..."
kubectl version --client --short 2>/dev/null || echo "❌ kubectl not working"

echo
echo "🔗 Getting current kubectl context..."
kubectl config current-context 2>/dev/null || echo "❌ No kubectl context set"

print_section "STEP 3: AKS Cluster Status"

echo "🎯 Attempting to reconnect to AKS cluster..."
echo "Run these commands manually if needed:"
echo
echo "# Reconnect to AKS cluster"
echo "az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks --overwrite-existing"
echo
echo "# Or try the dev cluster if main cluster has issues"
echo "az aks get-credentials --resource-group video-streaming-dev-rg --name video-streaming-dev-aks --overwrite-existing"

print_section "STEP 4: Grafana Deployment Check"

echo "🔍 Checking Grafana deployment status..."
echo "Run these commands to check Grafana:"
echo
echo "# Check all pods in video-streaming namespace"
echo "kubectl get pods -n video-streaming"
echo
echo "# Check specifically for Grafana pods"
echo "kubectl get pods -n video-streaming -l app=grafana-lite"
echo
echo "# Check Grafana service"
echo "kubectl get services -n video-streaming | grep grafana"

print_section "STEP 5: Grafana Recovery Options"

echo "🚀 Option A: Redeploy Grafana"
echo "kubectl delete deployment grafana-lite -n video-streaming"
echo "kubectl apply -f monitoring/grafana-lite.yaml"
echo
echo "🚀 Option B: Use existing Grafana deployment"
echo "kubectl apply -f monitoring/3-grafana.yaml"
echo
echo "🚀 Option C: Quick Grafana deployment"
cat << 'EOF'
kubectl apply -f - << 'GRAFANA_YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-quick
  namespace: video-streaming
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-quick
  template:
    metadata:
      labels:
        app: grafana-quick
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-quick-service
  namespace: video-streaming
spec:
  selector:
    app: grafana-quick
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
GRAFANA_YAML
EOF

print_section "STEP 6: Access Grafana"

echo "🌐 Once Grafana is running, access it with:"
echo
echo "# Option A: Port forwarding (recommended)"
echo "kubectl port-forward svc/grafana-lite-service 3000:3000 -n video-streaming"
echo "# Then open: http://localhost:3000"
echo
echo "# Option B: If using quick deployment"
echo "kubectl port-forward svc/grafana-quick-service 3000:3000 -n video-streaming"
echo "# Then open: http://localhost:3000"
echo
echo "# Option C: Check for external IP"
echo "kubectl get services -n video-streaming | grep grafana"
echo

print_section "STEP 7: Grafana Credentials"

echo "🔑 Try these login combinations:"
echo "1. Username: admin, Password: video_admin"
echo "2. Username: admin, Password: admin123"
echo "3. Username: admin, Password: admin"
echo

print_section "STEP 8: Terminal Issues Fix"

echo "🔧 If terminals keep crashing, try:"
echo "1. Close VS Code completely"
echo "2. Restart VS Code"
echo "3. Open a new terminal"
echo "4. Or use Windows Command Prompt instead of Git Bash"
echo "5. Use PowerShell as alternative: kubectl commands work in PowerShell too"

print_section "STEP 9: Alternative Access Methods"

echo "🎯 If port forwarding fails:"
echo
echo "# Method 1: kubectl proxy"
echo "kubectl proxy --port=8080"
echo "# Then access: http://localhost:8080/api/v1/namespaces/video-streaming/services/grafana-lite-service:3000/proxy/"
echo
echo "# Method 2: Direct pod access"
echo "POD_NAME=\$(kubectl get pods -n video-streaming -l app=grafana-lite -o jsonpath='{.items[0].metadata.name}')"
echo "kubectl port-forward pod/\$POD_NAME 3000:3000 -n video-streaming"

print_section "STEP 10: Quick Status Check Commands"

echo "📊 Run these for quick diagnostics:"
echo
echo "# Check cluster status"
echo "kubectl cluster-info"
echo
echo "# Check node status"
echo "kubectl get nodes"
echo
echo "# Check all namespaces"
echo "kubectl get namespaces"
echo
echo "# Check video-streaming namespace specifically"
echo "kubectl get all -n video-streaming"

print_section "EMERGENCY CONTACTS & RESOURCES"

echo "📚 Documentation files to check:"
echo "- GRAFANA_ACCESS_GUIDE.md"
echo "- IMPLEMENTATION_COMPLETE.md"
echo "- MONITORING_DEPLOYMENT_STATUS.md"
echo
echo "🆘 If all else fails:"
echo "1. Check if Azure subscription is active"
echo "2. Verify AKS cluster is running in Azure portal"
echo "3. Check if resource group 'video-streaming-rg' exists"
echo "4. Restart the entire monitoring stack: ./deploy-monitoring.sh"

print_section "SUMMARY"

echo "✅ Most likely fixes:"
echo "1. Reconnect to AKS: az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks"
echo "2. Redeploy Grafana: kubectl apply -f monitoring/grafana-lite.yaml"
echo "3. Port forward: kubectl port-forward svc/grafana-lite-service 3000:3000 -n video-streaming"
echo "4. Login with: admin/video_admin or admin/admin123"
echo
echo "🎯 Run these commands step by step and Grafana should work!"
echo
echo "Script completed at: $(date)"
