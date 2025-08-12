#!/bin/bash

# 🚀 Azure Video Streaming Network Monitoring Deployment Script
# Comprehensive monitoring and analytics deployment for Azure AKS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="video-streaming"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Azure Video Streaming Network Monitoring Setup${NC}"
echo "=================================================="

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}📋 Checking prerequisites...${NC}"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed${NC}"
        exit 1
    fi
    
    # Check AKS cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ No connection to Kubernetes cluster${NC}"
        echo "Please connect to your AKS cluster first:"
        echo "az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks"
        exit 1
    fi
    
    # Check namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo -e "${RED}❌ Namespace '$NAMESPACE' does not exist${NC}"
        echo "Please ensure your video streaming application is deployed first"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to deploy monitoring components
deploy_monitoring() {
    echo -e "${BLUE}📊 Deploying monitoring components...${NC}"
    
    # Deploy Prometheus
    echo "Deploying Prometheus..."
    kubectl apply -f "$SCRIPT_DIR/1-prometheus.yaml"
    kubectl apply -f "$SCRIPT_DIR/2-prometheus-config.yaml"
    
    # Wait for Prometheus to be ready
    echo "Waiting for Prometheus to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n "$NAMESPACE"
    
    # Deploy exporters
    echo "Deploying monitoring exporters..."
    kubectl apply -f "$SCRIPT_DIR/5-network-exporter.yaml"
    kubectl apply -f "$SCRIPT_DIR/6-postgres-exporter.yaml"
    kubectl apply -f "$SCRIPT_DIR/7-redis-exporter.yaml"
    
    # Deploy Grafana
    echo "Deploying Grafana..."
    kubectl apply -f "$SCRIPT_DIR/4-grafana-datasources.yaml"
    kubectl apply -f "$SCRIPT_DIR/8-grafana-dashboards.yaml"
    kubectl apply -f "$SCRIPT_DIR/3-grafana.yaml"
    
    # Wait for Grafana to be ready
    echo "Waiting for Grafana to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n "$NAMESPACE"
    
    echo -e "${GREEN}✅ Monitoring components deployed${NC}"
}

# Function to update backend with metrics collection
update_backend_metrics() {
    echo -e "${BLUE}📈 Updating backend with enhanced metrics...${NC}"
    
    # Add metrics collection libraries to requirements
    BACKEND_DIR="$SCRIPT_DIR/../backend"
    
    if [ -f "$BACKEND_DIR/requirements.txt" ]; then
        # Add metrics dependencies if not already present
        grep -qxF "prometheus-client==0.17.1" "$BACKEND_DIR/requirements.txt" || echo "prometheus-client==0.17.1" >> "$BACKEND_DIR/requirements.txt"
        grep -qxF "psutil==5.9.5" "$BACKEND_DIR/requirements.txt" || echo "psutil==5.9.5" >> "$BACKEND_DIR/requirements.txt"
        grep -qxF "aiohttp==3.8.5" "$BACKEND_DIR/requirements.txt" || echo "aiohttp==3.8.5" >> "$BACKEND_DIR/requirements.txt"
        
        echo "Updated backend requirements with monitoring dependencies"
    fi
    
    # Restart backend deployment to pick up new metrics
    if kubectl get deployment backend-api -n "$NAMESPACE" &> /dev/null; then
        echo "Restarting backend to enable metrics collection..."
        kubectl rollout restart deployment/backend-api -n "$NAMESPACE"
        kubectl wait --for=condition=available --timeout=300s deployment/backend-api -n "$NAMESPACE"
    fi
    
    echo -e "${GREEN}✅ Backend metrics updated${NC}"
}

# Function to configure Azure Monitor integration
configure_azure_monitor() {
    echo -e "${BLUE}☁️ Configuring Azure Monitor integration...${NC}"
    
    # Create Azure Monitor configuration secret
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: azure-monitor-config
  namespace: $NAMESPACE
type: Opaque
stringData:
  AZURE_SUBSCRIPTION_ID: "${AZURE_SUBSCRIPTION_ID:-demo-subscription}"
  AZURE_TENANT_ID: "${AZURE_TENANT_ID:-demo-tenant}"
  AZURE_CLIENT_ID: "${AZURE_CLIENT_ID:-demo-client}"
  AZURE_CLIENT_SECRET: "${AZURE_CLIENT_SECRET:-demo-secret}"
  AZURE_RESOURCE_GROUP: "video-streaming-rg"
  AKS_CLUSTER_NAME: "video-streaming-aks"
EOF
    
    echo -e "${GREEN}✅ Azure Monitor configuration created${NC}"
    echo -e "${YELLOW}⚠️  For full Azure Monitor integration, set these environment variables:${NC}"
    echo "   export AZURE_SUBSCRIPTION_ID=your-subscription-id"
    echo "   export AZURE_TENANT_ID=your-tenant-id"
    echo "   export AZURE_CLIENT_ID=your-client-id"
    echo "   export AZURE_CLIENT_SECRET=your-client-secret"
}

# Function to get service URLs
get_service_urls() {
    echo -e "${BLUE}🌐 Getting service URLs...${NC}"
    
    # Wait for LoadBalancer services to get external IPs
    echo "Waiting for external IP addresses..."
    sleep 30
    
    # Get Prometheus URL
    PROMETHEUS_IP=$(kubectl get svc prometheus-external -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    # Get Grafana URL
    GRAFANA_IP=$(kubectl get svc grafana-external -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    # Get Video Streaming URL (if exists)
    VIDEO_IP=$(kubectl get svc frontend-service -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    echo ""
    echo -e "${GREEN}📊 Monitoring Dashboard URLs:${NC}"
    echo "=================================="
    
    if [ "$GRAFANA_IP" != "pending" ]; then
        echo -e "${GREEN}🎨 Grafana:${NC} http://$GRAFANA_IP:3000"
        echo "   Username: admin"
        echo "   Password: video_streaming_admin"
    else
        echo -e "${YELLOW}🎨 Grafana:${NC} IP pending, check with: kubectl get svc grafana-external -n $NAMESPACE"
    fi
    
    if [ "$PROMETHEUS_IP" != "pending" ]; then
        echo -e "${GREEN}📈 Prometheus:${NC} http://$PROMETHEUS_IP:9090"
    else
        echo -e "${YELLOW}📈 Prometheus:${NC} IP pending, check with: kubectl get svc prometheus-external -n $NAMESPACE"
    fi
    
    if [ "$VIDEO_IP" != "pending" ]; then
        echo -e "${GREEN}🎥 Video Streaming:${NC} http://$VIDEO_IP"
        echo -e "${GREEN}📊 Video Metrics:${NC} http://$VIDEO_IP/metrics"
    else
        echo -e "${YELLOW}🎥 Video Streaming:${NC} IP pending, check with: kubectl get svc frontend-service -n $NAMESPACE"
    fi
    
    echo ""
}

# Function to show monitoring commands
show_monitoring_commands() {
    echo -e "${BLUE}🛠️ Monitoring Management Commands:${NC}"
    echo "====================================="
    echo ""
    echo "📊 Check monitoring status:"
    echo "   kubectl get pods -n $NAMESPACE | grep -E '(prometheus|grafana|exporter)'"
    echo ""
    echo "📈 View Prometheus metrics:"
    echo "   kubectl port-forward svc/prometheus-service 9090:9090 -n $NAMESPACE"
    echo "   # Then visit http://localhost:9090"
    echo ""
    echo "🎨 Access Grafana dashboards:"
    echo "   kubectl port-forward svc/grafana-service 3000:3000 -n $NAMESPACE"
    echo "   # Then visit http://localhost:3000"
    echo ""
    echo "🔍 View logs:"
    echo "   kubectl logs -l app=prometheus -n $NAMESPACE"
    echo "   kubectl logs -l app=grafana -n $NAMESPACE"
    echo ""
    echo "📋 Scale monitoring components:"
    echo "   kubectl scale deployment prometheus --replicas=2 -n $NAMESPACE"
    echo "   kubectl scale deployment grafana --replicas=2 -n $NAMESPACE"
    echo ""
    echo "🧹 Cleanup monitoring:"
    echo "   kubectl delete -f monitoring/ -n $NAMESPACE"
    echo ""
}

# Function to show available dashboards
show_dashboards() {
    echo -e "${BLUE}📊 Available Grafana Dashboards:${NC}"
    echo "=================================="
    echo ""
    echo "🎥 Video Streaming Platform - Overview"
    echo "   • Active video streams and uploads"
    echo "   • Data served and user metrics"
    echo "   • Stream activity trends"
    echo "   • Video quality distribution"
    echo ""
    echo "☁️ Azure Infrastructure Monitoring"
    echo "   • AKS cluster CPU and memory usage"
    echo "   • Network latency and bandwidth"
    echo "   • Pod status and health"
    echo "   • Network connections"
    echo ""
    echo "🌐 Network Performance Analytics"
    echo "   • Network latency trends"
    echo "   • Bandwidth utilization"
    echo "   • Packet loss monitoring"
    echo "   • Video streaming quality events"
    echo ""
    echo "💰 Azure Cost Monitoring"
    echo "   • Monthly Azure spend tracking"
    echo "   • Budget utilization gauge"
    echo "   • Projected costs"
    echo "   • Cost breakdown by service"
    echo ""
}

# Function to run health checks
run_health_checks() {
    echo -e "${BLUE}🔍 Running health checks...${NC}"
    
    # Check if all monitoring pods are running
    PROMETHEUS_STATUS=$(kubectl get pods -n "$NAMESPACE" -l app=prometheus -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    GRAFANA_STATUS=$(kubectl get pods -n "$NAMESPACE" -l app=grafana -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    
    echo ""
    echo "🔍 Component Status:"
    echo "==================="
    
    if [ "$PROMETHEUS_STATUS" = "Running" ]; then
        echo -e "${GREEN}✅ Prometheus: Running${NC}"
    else
        echo -e "${RED}❌ Prometheus: $PROMETHEUS_STATUS${NC}"
    fi
    
    if [ "$GRAFANA_STATUS" = "Running" ]; then
        echo -e "${GREEN}✅ Grafana: Running${NC}"
    else
        echo -e "${RED}❌ Grafana: $GRAFANA_STATUS${NC}"
    fi
    
    # Check exporters
    EXPORTERS=("network-exporter" "postgres-exporter" "redis-exporter")
    for exporter in "${EXPORTERS[@]}"; do
        STATUS=$(kubectl get pods -n "$NAMESPACE" -l app="$exporter" -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
        if [ "$STATUS" = "Running" ]; then
            echo -e "${GREEN}✅ $exporter: Running${NC}"
        else
            echo -e "${YELLOW}⚠️  $exporter: $STATUS${NC}"
        fi
    done
    
    echo ""
}

# Main execution
main() {
    check_prerequisites
    deploy_monitoring
    update_backend_metrics
    configure_azure_monitor
    
    echo ""
    echo -e "${GREEN}🎉 Azure Video Streaming Network Monitoring deployed successfully!${NC}"
    echo ""
    
    run_health_checks
    get_service_urls
    show_dashboards
    show_monitoring_commands
    
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "1. Wait for LoadBalancer IPs to be assigned (may take 2-5 minutes)"
    echo "2. Access Grafana dashboards using the URL above"
    echo "3. Configure Azure Monitor credentials for full integration"
    echo "4. Set up alerting rules in Prometheus"
    echo "5. Configure log aggregation with Azure Log Analytics"
    echo ""
    echo -e "${GREEN}🚀 Your video streaming platform now has comprehensive monitoring!${NC}"
}

# Execute main function
main "$@"
