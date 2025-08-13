#!/bin/bash

# 🎯 Network Monitoring Dashboard Access Script
# Quick access to monitoring tools and analytics

echo "🎯 Azure Video Streaming - Network Monitoring Dashboard"
echo "=================================================="
echo

# Function to check service status
check_service() {
    local service=$1
    local namespace=$2
    echo "🔍 Checking $service..."
    kubectl get pods -l app=$service -n $namespace --no-headers 2>/dev/null | grep Running >/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ $service is running"
        return 0
    else
        echo "❌ $service is not running"
        return 1
    fi
}

# Function to get external IPs
get_external_ips() {
    echo "🌐 External Access Points:"
    echo "========================"
    kubectl get services -n video-streaming -o wide | grep LoadBalancer | while read line; do
        name=$(echo $line | awk '{print $1}')
        external_ip=$(echo $line | awk '{print $4}')
        port=$(echo $line | awk '{print $5}' | cut -d: -f1)
        
        if [ "$external_ip" != "<pending>" ] && [ "$external_ip" != "<none>" ]; then
            echo "✅ $name: http://$external_ip:$port"
        else
            echo "⏳ $name: IP pending..."
        fi
    done
    echo
}

# Function to start port forwarding
start_port_forward() {
    local service=$1
    local local_port=$2
    local remote_port=$3
    local description=$4
    
    echo "🚀 Starting port forward for $description..."
    kubectl port-forward svc/$service $local_port:$remote_port -n video-streaming &
    local pid=$!
    echo "📍 Access at: http://localhost:$local_port"
    echo "🔧 PID: $pid (use 'kill $pid' to stop)"
    echo
}

# Function to show quick metrics
show_quick_metrics() {
    echo "📊 Quick Metrics Summary:"
    echo "========================"
    
    # Check if main application is accessible
    echo "🎥 Video Platform Status:"
    curl -s -o /dev/null -w "  Response Code: %{http_code}\n  Response Time: %{time_total}s\n" http://57.152.79.140:8000/health
    echo
    
    # Show pod status
    echo "📱 Pod Status:"
    kubectl get pods -n video-streaming --no-headers | while read line; do
        name=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $3}')
        if [ "$status" = "Running" ]; then
            echo "  ✅ $name"
        else
            echo "  ❌ $name ($status)"
        fi
    done
    echo
    
    # Show resource usage
    echo "💾 Resource Usage:"
    kubectl top pods -n video-streaming 2>/dev/null | tail -n +2 | while read line; do
        echo "  📊 $line"
    done 2>/dev/null || echo "  ⚠️  Metrics server not available"
    echo
}

# Function to test endpoints
test_endpoints() {
    echo "🧪 Testing Monitoring Endpoints:"
    echo "==============================="
    
    local base_url="http://57.152.79.140:8000"
    
    endpoints=(
        "/health:Health Check"
        "/metrics:Prometheus Metrics"
        "/api/streams:Stream Status"
        "/api/sessions:Active Sessions"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        endpoint=$(echo $endpoint_info | cut -d: -f1)
        description=$(echo $endpoint_info | cut -d: -f2)
        
        echo -n "  🔍 $description ($endpoint)... "
        response=$(curl -s -o /dev/null -w "%{http_code}" "$base_url$endpoint" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            echo "✅ OK"
        elif [ "$response" = "404" ]; then
            echo "❌ Not Found"
        else
            echo "⚠️  Response: $response"
        fi
    done
    echo
}

# Main menu function
show_menu() {
    echo "🎯 Choose an action:"
    echo "=================="
    echo "1. 📊 Show Service Status"
    echo "2. 🌐 Show External IPs"
    echo "3. 📈 Start Prometheus Dashboard (port 9090)"
    echo "4. 📊 Start Grafana Dashboard (port 3000)"
    echo "5. 🧪 Test Monitoring Endpoints"
    echo "6. 📊 Show Quick Metrics"
    echo "7. 🔄 Full Status Report"
    echo "8. 🚀 Open Video Platform"
    echo "9. ❌ Exit"
    echo
    read -p "Enter your choice (1-9): " choice
    echo
}

# Main execution
main() {
    while true; do
        show_menu
        
        case $choice in
            1)
                echo "🔍 Service Status Check:"
                echo "======================="
                services=("backend-api" "frontend" "postgres" "redis" "prometheus-lite" "grafana-lite")
                for service in "${services[@]}"; do
                    check_service $service video-streaming
                done
                echo
                ;;
            2)
                get_external_ips
                ;;
            3)
                start_port_forward "prometheus-lite-service" 9090 9090 "Prometheus Dashboard"
                ;;
            4)
                start_port_forward "grafana-lite-service" 3000 3000 "Grafana Dashboard"
                echo "📝 Default Grafana credentials: admin/admin"
                echo
                ;;
            5)
                test_endpoints
                ;;
            6)
                show_quick_metrics
                ;;
            7)
                echo "📋 Full Status Report:"
                echo "===================="
                check_service "backend-api" "video-streaming"
                check_service "prometheus-lite" "video-streaming"
                check_service "grafana-lite" "video-streaming"
                echo
                get_external_ips
                test_endpoints
                show_quick_metrics
                ;;
            8)
                echo "🚀 Opening video platform..."
                echo "🌐 URL: http://57.152.79.140"
                if command -v xdg-open > /dev/null; then
                    xdg-open http://57.152.79.140
                elif command -v open > /dev/null; then
                    open http://57.152.79.140
                else
                    echo "📋 Please open http://57.152.79.140 in your browser"
                fi
                echo
                ;;
            9)
                echo "👋 Goodbye!"
                break
                ;;
            *)
                echo "❌ Invalid choice. Please try again."
                echo
                ;;
        esac
        
        read -p "Press Enter to continue..."
        clear
    done
}

# Quick status check if run with --status
if [ "$1" = "--status" ]; then
    echo "🎯 Quick Status Check:"
    echo "===================="
    get_external_ips
    show_quick_metrics
    exit 0
fi

# Quick endpoint test if run with --test
if [ "$1" = "--test" ]; then
    test_endpoints
    exit 0
fi

# Show help if run with --help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "🎯 Network Monitoring Dashboard - Help"
    echo "====================================="
    echo
    echo "Usage: $0 [option]"
    echo
    echo "Options:"
    echo "  --status    Quick status overview"
    echo "  --test      Test monitoring endpoints"
    echo "  --help, -h  Show this help message"
    echo
    echo "Interactive mode:"
    echo "  Run without arguments for interactive menu"
    echo
    echo "Quick Access Commands:"
    echo "  kubectl port-forward svc/prometheus-lite-service 9090:9090 -n video-streaming"
    echo "  kubectl port-forward svc/grafana-lite-service 3000:3000 -n video-streaming"
    echo
    exit 0
fi

# Start interactive mode
clear
main
