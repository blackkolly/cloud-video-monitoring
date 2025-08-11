#!/bin/bash

# 🎥 Cloud Video Network Monitoring Platform - One-Click Deployment
# Enterprise-grade video streaming network infrastructure deployment script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
ENVIRONMENT="development"
CLOUDS=""
DEPLOY_CDN="true"
DEPLOY_MONITORING="true"
DEPLOY_SECURITY="true"
NAMESPACE="video-monitoring"
HELM_RELEASE="video-monitor"
DRY_RUN="false"

# Banner
print_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════╗
    ║          🎥 Cloud Video Network Monitoring Platform            ║
    ║                Enterprise Deployment Script                    ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again"
        exit 1
    fi
    
    # Check Kubernetes cluster connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Please configure kubectl and ensure cluster is accessible"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --environment|-e)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --clouds|-c)
                CLOUDS="$2"
                shift 2
                ;;
            --namespace|-n)
                NAMESPACE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --no-cdn)
                DEPLOY_CDN="false"
                shift
                ;;
            --no-monitoring)
                DEPLOY_MONITORING="false"
                shift
                ;;
            --no-security)
                DEPLOY_SECURITY="false"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat << EOF
🎥 Cloud Video Network Monitoring Platform Deployment

Usage: $0 [OPTIONS]

OPTIONS:
    --environment, -e    Deployment environment (development|staging|production) [default: development]
    --clouds, -c         Comma-separated list of clouds (aws,azure,gcp) [default: all]
    --namespace, -n      Kubernetes namespace [default: video-monitoring]
    --dry-run           Show what would be deployed without actually deploying
    --no-cdn            Skip CDN integration deployment
    --no-monitoring     Skip monitoring stack deployment
    --no-security       Skip security components deployment
    --help, -h          Show this help message

EXAMPLES:
    # Deploy to production with all clouds
    $0 --environment production --clouds aws,azure,gcp
    
    # Deploy to staging with monitoring only
    $0 --environment staging --no-cdn --no-security
    
    # Dry run for development
    $0 --environment development --dry-run

EOF
}

# Setup namespace
setup_namespace() {
    log_info "Setting up Kubernetes namespace: $NAMESPACE"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would create namespace $NAMESPACE"
        return
    fi
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace "$NAMESPACE" app=video-monitoring --overwrite
    
    log_success "Namespace $NAMESPACE ready"
}

# Deploy monitoring stack
deploy_monitoring() {
    if [[ "$DEPLOY_MONITORING" != "true" ]]; then
        log_info "Skipping monitoring stack deployment"
        return
    fi
    
    log_info "Deploying monitoring stack..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would deploy monitoring stack"
        return
    fi
    
    # Add Prometheus community Helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Deploy Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --values k8s/monitoring/prometheus-values.yaml \
        --wait
    
    # Deploy custom video monitoring components
    kubectl apply -f k8s/monitoring/ -n "$NAMESPACE"
    
    log_success "Monitoring stack deployed"
}

# Deploy CDN integration
deploy_cdn() {
    if [[ "$DEPLOY_CDN" != "true" ]]; then
        log_info "Skipping CDN integration deployment"
        return
    fi
    
    log_info "Deploying CDN integration components..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would deploy CDN integration"
        return
    fi
    
    kubectl apply -f k8s/cdn-integration/ -n "$NAMESPACE"
    
    log_success "CDN integration deployed"
}

# Deploy security components
deploy_security() {
    if [[ "$DEPLOY_SECURITY" != "true" ]]; then
        log_info "Skipping security components deployment"
        return
    fi
    
    log_info "Deploying security components..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would deploy security components"
        return
    fi
    
    kubectl apply -f k8s/security/ -n "$NAMESPACE"
    
    log_success "Security components deployed"
}

# Deploy main application
deploy_application() {
    log_info "Deploying main video monitoring application..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would deploy main application"
        return
    fi
    
    # Deploy main application components
    kubectl apply -f k8s/core/ -n "$NAMESPACE"
    
    # Wait for deployments to be ready
    kubectl wait --for=condition=available --timeout=300s deployment --all -n "$NAMESPACE"
    
    log_success "Main application deployed"
}

# Setup cloud-specific configurations
setup_cloud_configs() {
    if [[ -z "$CLOUDS" ]]; then
        log_info "No specific clouds configured, using default configuration"
        return
    fi
    
    IFS=',' read -ra CLOUD_ARRAY <<< "$CLOUDS"
    for cloud in "${CLOUD_ARRAY[@]}"; do
        log_info "Setting up configuration for $cloud"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "DRY RUN: Would setup $cloud configuration"
            continue
        fi
        
        case $cloud in
            aws)
                kubectl apply -f k8s/clouds/aws/ -n "$NAMESPACE"
                ;;
            azure)
                kubectl apply -f k8s/clouds/azure/ -n "$NAMESPACE"
                ;;
            gcp)
                kubectl apply -f k8s/clouds/gcp/ -n "$NAMESPACE"
                ;;
            *)
                log_warning "Unknown cloud provider: $cloud"
                ;;
        esac
    done
    
    log_success "Cloud configurations applied"
}

# Show deployment status
show_status() {
    log_info "Deployment Status:"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN completed - no actual resources deployed"
        return
    fi
    
    echo -e "${CYAN}Namespace:${NC} $NAMESPACE"
    echo -e "${CYAN}Environment:${NC} $ENVIRONMENT"
    echo -e "${CYAN}Clouds:${NC} ${CLOUDS:-"default"}"
    echo ""
    
    # Show pod status
    echo -e "${CYAN}Pod Status:${NC}"
    kubectl get pods -n "$NAMESPACE" -o wide
    echo ""
    
    # Show service status
    echo -e "${CYAN}Service Status:${NC}"
    kubectl get services -n "$NAMESPACE"
    echo ""
    
    # Show ingress status if available
    if kubectl get ingress -n "$NAMESPACE" >/dev/null 2>&1; then
        echo -e "${CYAN}Ingress Status:${NC}"
        kubectl get ingress -n "$NAMESPACE"
        echo ""
    fi
    
    # Show access URLs
    show_access_urls
}

# Show access URLs
show_access_urls() {
    log_info "Access URLs:"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        return
    fi
    
    # Get service URLs
    local grafana_port=$(kubectl get service prometheus-grafana -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "3000")
    local prometheus_port=$(kubectl get service prometheus-kube-prometheus-prometheus -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "9090")
    
    echo -e "${GREEN}📊 Grafana Dashboard:${NC} http://localhost:$grafana_port"
    echo -e "${GREEN}📈 Prometheus:${NC} http://localhost:$prometheus_port"
    echo -e "${GREEN}🎥 Video Analytics:${NC} http://localhost:8080"
    echo ""
    
    log_info "Use 'kubectl port-forward' to access services locally:"
    echo "kubectl port-forward -n $NAMESPACE service/prometheus-grafana 3000:80"
    echo "kubectl port-forward -n $NAMESPACE service/prometheus-kube-prometheus-prometheus 9090:9090"
}

# Cleanup function
cleanup() {
    if [[ "$1" != "0" ]]; then
        log_error "Deployment failed!"
        log_info "Check the logs above for error details"
        log_info "You can cleanup with: kubectl delete namespace $NAMESPACE"
    fi
}

# Main execution
main() {
    # Set trap for cleanup
    trap 'cleanup $?' EXIT
    
    print_banner
    
    parse_arguments "$@"
    check_prerequisites
    
    log_info "Starting deployment with configuration:"
    log_info "Environment: $ENVIRONMENT"
    log_info "Clouds: ${CLOUDS:-"default"}"
    log_info "Namespace: $NAMESPACE"
    log_info "Dry Run: $DRY_RUN"
    echo ""
    
    setup_namespace
    setup_cloud_configs
    deploy_monitoring
    deploy_cdn
    deploy_security
    deploy_application
    
    show_status
    
    log_success "🎉 Deployment completed successfully!"
    log_info "The video monitoring platform is now ready for use"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Access the dashboards using the URLs shown above"
        log_info "For troubleshooting, check: kubectl logs -n $NAMESPACE -l app=video-monitoring"
    fi
}

# Execute main function with all arguments
main "$@"
