#!/bin/bash

# 🎯 Grafana Access Guide
# Quick access script for Grafana dashboard

echo "🎯 Grafana Dashboard Access Guide"
echo "================================"
echo

# Check if Grafana pod is running
echo "🔍 Checking Grafana status..."
kubectl get pods -n video-streaming -l app=grafana-lite

echo
echo "🚀 Setting up Grafana access..."

# Kill any existing port forwards
echo "🔧 Cleaning up existing port forwards..."
pkill -f "port-forward.*grafana" 2>/dev/null || true
sleep 2

# Start port forwarding
echo "🌐 Starting port forward to Grafana..."
kubectl port-forward svc/grafana-lite-service 3001:3000 -n video-streaming &
GRAFANA_PID=$!

echo "📋 Grafana Access Information:"
echo "=============================="
echo "🌐 URL: http://localhost:3001"
echo "👤 Username: admin"
echo "🔑 Password: video_admin"
echo
echo "📍 Port Forward PID: $GRAFANA_PID"
echo "🛑 To stop: kill $GRAFANA_PID"
echo

# Wait a moment for port forward to establish
sleep 3

# Test connection
echo "🧪 Testing Grafana connection..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/login 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Grafana is accessible at http://localhost:3001"
    echo "🎯 Ready to login with admin/video_admin"
else
    echo "⚠️  Connection test returned HTTP $HTTP_CODE"
    echo "🔧 Please wait a moment and try accessing http://localhost:3001"
fi

echo
echo "🎯 Next Steps:"
echo "1. Open http://localhost:3001 in your browser"
echo "2. Login with username: admin, password: video_admin"
echo "3. Add Prometheus data source: http://prometheus-lite-service:9090"
echo "4. Import dashboards for monitoring your video streaming platform"
echo

# Keep script running to maintain port forward
echo "⏳ Port forward is active. Press Ctrl+C to stop..."
wait $GRAFANA_PID
