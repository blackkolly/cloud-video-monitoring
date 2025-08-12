#!/bin/bash

# 🎯 Network Monitoring Analytics - Azure Video Streaming Platform
# Complete deployment and configuration guide

echo "🚀 Azure Video Streaming Network Monitoring & Analytics"
echo "======================================================="
echo ""

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to deploy monitoring to Azure AKS
deploy_to_azure() {
    echo -e "${BLUE}☁️ Deploying to Azure AKS...${NC}"
    
    # Check if connected to AKS
    if ! kubectl cluster-info | grep -q "kubernetes.default.svc.cluster.local"; then
        echo -e "${YELLOW}⚠️  Connect to your AKS cluster first:${NC}"
        echo "az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks"
        exit 1
    fi
    
    echo "1. Deploying monitoring stack..."
    ./monitoring/deploy-monitoring.sh
    
    echo "2. Waiting for services to be ready..."
    sleep 60
    
    echo "3. Getting service URLs..."
    echo ""
    echo -e "${GREEN}📊 Your Azure Video Streaming Analytics URLs:${NC}"
    echo "=============================================="
    
    # Get external IPs
    GRAFANA_IP=$(kubectl get svc grafana-external -n video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    PROMETHEUS_IP=$(kubectl get svc prometheus-external -n video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    VIDEO_IP=$(kubectl get svc frontend-service -n video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    if [ "$GRAFANA_IP" != "pending" ]; then
        echo -e "${GREEN}🎨 Grafana Analytics:${NC} http://$GRAFANA_IP:3000"
        echo "   Username: admin"
        echo "   Password: video_streaming_admin"
    else
        echo -e "${YELLOW}🎨 Grafana:${NC} IP pending..."
    fi
    
    if [ "$PROMETHEUS_IP" != "pending" ]; then
        echo -e "${GREEN}📈 Prometheus Metrics:${NC} http://$PROMETHEUS_IP:9090"
    else
        echo -e "${YELLOW}📈 Prometheus:${NC} IP pending..."
    fi
    
    if [ "$VIDEO_IP" != "pending" ]; then
        echo -e "${GREEN}🎥 Video Platform:${NC} http://$VIDEO_IP"
        echo -e "${GREEN}📊 API Metrics:${NC} http://$VIDEO_IP/metrics"
        echo -e "${GREEN}📈 Real-time Analytics:${NC} http://$VIDEO_IP/api/analytics/realtime"
    else
        echo -e "${YELLOW}🎥 Video Platform:${NC} IP pending..."
    fi
    
    echo ""
}

# Function to show comprehensive analytics features
show_analytics_features() {
    echo -e "${BLUE}📊 Comprehensive Network Monitoring & Analytics Features${NC}"
    echo "========================================================="
    echo ""
    
    echo "🎥 VIDEO STREAMING ANALYTICS:"
    echo "   • Real-time active streams monitoring"
    echo "   • Video upload tracking and metrics"
    echo "   • Bandwidth utilization analysis"
    echo "   • Quality distribution monitoring"
    echo "   • User engagement analytics"
    echo ""
    
    echo "🌐 NETWORK PERFORMANCE MONITORING:"
    echo "   • End-to-end latency tracking"
    echo "   • Packet loss detection and analysis"
    echo "   • Bandwidth utilization monitoring"
    echo "   • Network jitter and stability metrics"
    echo "   • Multi-region performance comparison"
    echo ""
    
    echo "☁️ AZURE INFRASTRUCTURE MONITORING:"
    echo "   • AKS cluster CPU and memory monitoring"
    echo "   • Pod status and health tracking"
    echo "   • Load balancer performance metrics"
    echo "   • Storage utilization monitoring"
    echo "   • Network security group analysis"
    echo ""
    
    echo "💰 AZURE COST ANALYTICS:"
    echo "   • Real-time cost tracking"
    echo "   • Budget utilization monitoring"
    echo "   • Service-wise cost breakdown"
    echo "   • Projected monthly costs"
    echo "   • Resource optimization recommendations"
    echo ""
    
    echo "📈 ADVANCED ANALYTICS:"
    echo "   • User behavior and engagement analysis"
    echo "   • Content performance metrics"
    echo "   • Quality of Experience (QoE) scoring"
    echo "   • Predictive analytics and alerts"
    echo "   • Custom dashboard creation"
    echo ""
}

# Function to show API endpoints
show_api_endpoints() {
    echo -e "${BLUE}🔗 Analytics API Endpoints${NC}"
    echo "=========================="
    echo ""
    
    echo "📊 REAL-TIME ANALYTICS:"
    echo "   GET /api/analytics/realtime     - Live streaming metrics"
    echo "   GET /api/analytics/network      - Network performance data"
    echo "   GET /api/analytics/engagement   - User engagement metrics"
    echo "   GET /api/analytics/report       - Comprehensive analytics report"
    echo ""
    
    echo "☁️ AZURE INTEGRATION:"
    echo "   GET /api/azure/aks-metrics      - AKS cluster metrics"
    echo "   GET /api/azure/network-metrics  - Azure network performance"
    echo "   GET /api/azure/cost-metrics     - Azure cost analysis"
    echo "   GET /api/azure/application-insights - Application performance"
    echo ""
    
    echo "📈 PROMETHEUS METRICS:"
    echo "   GET /metrics                    - Prometheus metrics endpoint"
    echo "   GET /api/metrics/summary        - Metrics summary"
    echo ""
    
    echo "🎥 VIDEO STREAMING:"
    echo "   GET /api/videos                 - List all videos"
    echo "   POST /api/upload               - Upload video with analytics"
    echo "   GET /stream/{video_id}         - Stream video with metrics"
    echo "   GET /api/stream/{video_id}/stats - Stream statistics"
    echo ""
}

# Function to show Grafana dashboard setup
show_grafana_setup() {
    echo -e "${BLUE}🎨 Grafana Dashboard Configuration${NC}"
    echo "=================================="
    echo ""
    
    echo "📊 AVAILABLE DASHBOARDS:"
    echo ""
    echo "1. VIDEO STREAMING OVERVIEW"
    echo "   • Active streams and uploads"
    echo "   • Data served metrics"
    echo "   • Quality distribution"
    echo "   • User activity trends"
    echo ""
    
    echo "2. AZURE INFRASTRUCTURE"
    echo "   • AKS cluster performance"
    echo "   • Network latency and bandwidth"
    echo "   • Pod status monitoring"
    echo "   • Resource utilization"
    echo ""
    
    echo "3. NETWORK PERFORMANCE"
    echo "   • Latency trend analysis"
    echo "   • Bandwidth utilization"
    echo "   • Packet loss tracking"
    echo "   • Quality event monitoring"
    echo ""
    
    echo "4. COST MONITORING"
    echo "   • Azure spend tracking"
    echo "   • Budget utilization"
    echo "   • Service cost breakdown"
    echo "   • Optimization recommendations"
    echo ""
    
    echo "🔧 DASHBOARD CUSTOMIZATION:"
    echo "   • Custom panels and queries"
    echo "   • Alert rule configuration"
    echo "   • Data source integration"
    echo "   • Export/import capabilities"
    echo ""
}

# Function to show monitoring best practices
show_best_practices() {
    echo -e "${BLUE}📋 Network Monitoring Best Practices${NC}"
    echo "===================================="
    echo ""
    
    echo "🎯 PERFORMANCE OPTIMIZATION:"
    echo "   • Monitor key metrics: latency, bandwidth, packet loss"
    echo "   • Set up automated alerts for threshold breaches"
    echo "   • Implement predictive analytics for capacity planning"
    echo "   • Regular performance baseline reviews"
    echo ""
    
    echo "💰 COST OPTIMIZATION:"
    echo "   • Enable Azure cost alerts and budgets"
    echo "   • Monitor resource utilization trends"
    echo "   • Implement auto-scaling for cost efficiency"
    echo "   • Regular cost review and optimization"
    echo ""
    
    echo "🔒 SECURITY MONITORING:"
    echo "   • Monitor network security group rules"
    echo "   • Track unauthorized access attempts"
    echo "   • Implement DDoS protection monitoring"
    echo "   • Regular security baseline assessments"
    echo ""
    
    echo "📊 DATA RETENTION:"
    echo "   • Configure appropriate metric retention periods"
    echo "   • Archive historical data for trend analysis"
    echo "   • Implement data backup and recovery"
    echo "   • Regular data cleanup procedures"
    echo ""
}

# Function to show troubleshooting guide
show_troubleshooting() {
    echo -e "${BLUE}🔧 Troubleshooting Guide${NC}"
    echo "======================="
    echo ""
    
    echo "❌ COMMON ISSUES:"
    echo ""
    echo "1. Grafana not accessible:"
    echo "   kubectl get svc grafana-external -n video-streaming"
    echo "   kubectl logs -l app=grafana -n video-streaming"
    echo ""
    
    echo "2. Prometheus not collecting metrics:"
    echo "   kubectl get pods -l app=prometheus -n video-streaming"
    echo "   kubectl logs -l app=prometheus -n video-streaming"
    echo ""
    
    echo "3. Missing Azure metrics:"
    echo "   Check Azure credentials in backend logs"
    echo "   Verify Azure Monitor integration setup"
    echo ""
    
    echo "4. High costs:"
    echo "   Review resource utilization in dashboards"
    echo "   Check auto-scaling configuration"
    echo "   Implement cost optimization recommendations"
    echo ""
}

# Main menu
case "${1:-menu}" in
    "deploy")
        deploy_to_azure
        ;;
    "features")
        show_analytics_features
        ;;
    "api")
        show_api_endpoints
        ;;
    "dashboards")
        show_grafana_setup
        ;;
    "best-practices")
        show_best_practices
        ;;
    "troubleshooting")
        show_troubleshooting
        ;;
    *)
        echo "Usage: $0 {deploy|features|api|dashboards|best-practices|troubleshooting}"
        echo ""
        show_analytics_features
        echo ""
        echo -e "${YELLOW}🚀 To deploy: ./network-monitoring-guide.sh deploy${NC}"
        echo -e "${YELLOW}📊 For API docs: ./network-monitoring-guide.sh api${NC}"
        echo -e "${YELLOW}🎨 For dashboards: ./network-monitoring-guide.sh dashboards${NC}"
        ;;
esac
