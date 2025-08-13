#!/bin/bash

# 🔧 Grafana Troubleshooting & Recovery Script
# Complete diagnostic and recovery for Grafana monitoring

echo "🔧 Grafana Troubleshooting & Recovery"
echo "===================================="
echo

# Function to check Azure login
check_azure_login() {
    echo "🔍 Checking Azure CLI authentication..."
    if az account show >/dev/null 2>&1; then
        echo "✅ Azure CLI is authenticated"
        az account show --query '{subscriptionId:id, name:name, user:user.name}' -o table
        return 0
    else
        echo "❌ Azure CLI not authenticated"
        echo "📋 Please run: az login"
        return 1
    fi
}

# Function to check AKS connectivity
check_aks_connectivity() {
    echo "🔍 Checking AKS cluster connectivity..."
    
    # Check if cluster exists
    if az aks list --resource-group video-streaming-rg --query '[].name' -o tsv 2>/dev/null | grep -q video-streaming-aks; then
        echo "✅ AKS cluster 'video-streaming-aks' exists"
        
        # Get credentials
        echo "🔧 Getting AKS credentials..."
        az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks --overwrite-existing
        
        # Test connectivity
        if kubectl cluster-info >/dev/null 2>&1; then
            echo "✅ kubectl connectivity established"
            return 0
        else
            echo "❌ kubectl connectivity failed"
            return 1
        fi
    else
        echo "❌ AKS cluster not found"
        echo "📋 Available clusters:"
        az aks list --query '[].{Name:name, ResourceGroup:resourceGroup, Status:powerState.code}' -o table 2>/dev/null || echo "None found"
        return 1
    fi
}

# Function to check Grafana deployment
check_grafana_deployment() {
    echo "🔍 Checking Grafana deployment status..."
    
    # Check namespace
    if kubectl get namespace video-streaming >/dev/null 2>&1; then
        echo "✅ Namespace 'video-streaming' exists"
    else
        echo "❌ Namespace 'video-streaming' not found"
        echo "🔧 Creating namespace..."
        kubectl create namespace video-streaming
    fi
    
    # Check Grafana deployment
    if kubectl get deployment grafana-lite -n video-streaming >/dev/null 2>&1; then
        echo "✅ Grafana deployment exists"
        kubectl get deployment grafana-lite -n video-streaming
        
        # Check pods
        echo "📊 Grafana pod status:"
        kubectl get pods -n video-streaming -l app=grafana-lite
        
        # Check service
        echo "🌐 Grafana service status:"
        kubectl get service grafana-lite-service -n video-streaming
        
    else
        echo "❌ Grafana deployment not found"
        return 1
    fi
}

# Function to deploy Grafana
deploy_grafana() {
    echo "🚀 Deploying Grafana..."
    
    # Check if monitoring files exist
    if [ -f "monitoring/grafana-lite.yaml" ]; then
        echo "📁 Using existing grafana-lite.yaml"
        kubectl apply -f monitoring/grafana-lite.yaml
    else
        echo "📁 Creating new Grafana deployment..."
        cat > grafana-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-lite
  namespace: video-streaming
  labels:
    app: grafana-lite
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-lite
  template:
    metadata:
      labels:
        app: grafana-lite
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:10.0.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_SECURITY_ALLOW_EMBEDDING
          value: "true"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 300m
            memory: 512Mi
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-lite-service
  namespace: video-streaming
  labels:
    app: grafana-lite
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
  selector:
    app: grafana-lite
EOF
        
        kubectl apply -f grafana-deployment.yaml
    fi
    
    echo "⏳ Waiting for Grafana to start..."
    kubectl wait --for=condition=available --timeout=120s deployment/grafana-lite -n video-streaming
    
    if [ $? -eq 0 ]; then
        echo "✅ Grafana deployed successfully"
        return 0
    else
        echo "❌ Grafana deployment failed"
        return 1
    fi
}

# Function to setup port forwarding
setup_port_forwarding() {
    echo "🌐 Setting up Grafana port forwarding..."
    
    # Kill existing port forwards
    pkill -f "port-forward.*grafana" 2>/dev/null || true
    sleep 2
    
    # Find available port
    for port in 3001 3002 3003 3004; do
        if ! netstat -an 2>/dev/null | grep -q ":$port "; then
            echo "🔧 Using port $port for Grafana"
            kubectl port-forward svc/grafana-lite-service $port:3000 -n video-streaming &
            GRAFANA_PID=$!
            
            # Wait and test
            sleep 5
            if curl -s http://localhost:$port/login >/dev/null 2>&1; then
                echo "✅ Grafana accessible at http://localhost:$port"
                echo "🔑 Credentials: admin / admin123"
                echo "🔧 Port forward PID: $GRAFANA_PID"
                return 0
            fi
        fi
    done
    
    echo "❌ Could not establish port forwarding"
    return 1
}

# Function to check Grafana via external IP
check_external_access() {
    echo "🌐 Checking for external IP access..."
    
    EXTERNAL_IP=$(kubectl get service grafana-lite-service -n video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        echo "✅ External IP available: $EXTERNAL_IP"
        echo "🌐 Access Grafana at: http://$EXTERNAL_IP:3000"
        echo "🔑 Credentials: admin / admin123"
        return 0
    else
        echo "⏳ External IP not yet assigned"
        return 1
    fi
}

# Function to provide alternative solutions
provide_alternatives() {
    echo "🎯 Alternative Solutions:"
    echo "========================"
    echo
    echo "1. 🐳 Local Docker Grafana:"
    echo "   docker run -d -p 3000:3000 --name=grafana grafana/grafana:10.0.0"
    echo "   Access: http://localhost:3000 (admin/admin)"
    echo
    echo "2. 🔧 kubectl proxy method:"
    echo "   kubectl proxy --port=8080"
    echo "   Access: http://localhost:8080/api/v1/namespaces/video-streaming/services/grafana-lite-service:3000/proxy/"
    echo
    echo "3. 📊 Prometheus direct access:"
    echo "   kubectl port-forward svc/prometheus-lite-service 9090:9090 -n video-streaming"
    echo "   Access: http://localhost:9090"
    echo
    echo "4. 🌐 NodePort service:"
    echo "   kubectl patch service grafana-lite-service -n video-streaming -p '{\"spec\":{\"type\":\"NodePort\"}}'"
    echo
}

# Main troubleshooting flow
main() {
    echo "Starting comprehensive Grafana troubleshooting..."
    echo
    
    # Step 1: Check Azure authentication
    if ! check_azure_login; then
        echo "❌ Please authenticate with Azure first: az login"
        exit 1
    fi
    
    # Step 2: Check AKS connectivity
    if ! check_aks_connectivity; then
        echo "❌ Cannot connect to AKS cluster"
        provide_alternatives
        exit 1
    fi
    
    # Step 3: Check Grafana deployment
    if ! check_grafana_deployment; then
        echo "🔧 Grafana not found, deploying..."
        if ! deploy_grafana; then
            echo "❌ Failed to deploy Grafana"
            provide_alternatives
            exit 1
        fi
    fi
    
    # Step 4: Try external access first
    if check_external_access; then
        echo "🎉 Grafana is accessible via external IP!"
        exit 0
    fi
    
    # Step 5: Setup port forwarding
    if setup_port_forwarding; then
        echo "🎉 Grafana is accessible via port forwarding!"
        echo "⏳ Port forward is active. Press Ctrl+C to stop..."
        wait $GRAFANA_PID
    else
        echo "❌ Port forwarding failed"
        provide_alternatives
        exit 1
    fi
}

# Run main function
main "$@"
