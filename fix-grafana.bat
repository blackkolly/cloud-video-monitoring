@echo off
REM 🚨 Grafana Troubleshooting - Windows Batch Version
REM Fix for terminal and Grafana connectivity issues

echo 🚨 Grafana Emergency Fix - Windows Version
echo ==========================================
echo Current Date: %date% %time%
echo.

echo 🎯 STEP 1: Reconnect to AKS Cluster
echo ===================================
echo Running: az aks get-credentials...
az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks --overwrite-existing

echo.
echo 🎯 STEP 2: Check Cluster Connection
echo ==================================
kubectl cluster-info
kubectl get nodes

echo.
echo 🎯 STEP 3: Check Video Streaming Namespace
echo =========================================
kubectl get pods -n video-streaming
kubectl get services -n video-streaming

echo.
echo 🎯 STEP 4: Deploy/Redeploy Grafana
echo =================================
echo Applying Grafana deployment...
kubectl apply -f monitoring\grafana-lite.yaml

echo.
echo Waiting for Grafana to start...
timeout /t 30 /nobreak

echo.
echo 🎯 STEP 5: Check Grafana Status
echo ==============================
kubectl get pods -n video-streaming -l app=grafana-lite
kubectl get services -n video-streaming | findstr grafana

echo.
echo 🎯 STEP 6: Start Port Forwarding
echo ===============================
echo Starting port forward to Grafana...
echo This will open in a new window - DO NOT CLOSE IT
start cmd /k "kubectl port-forward svc/grafana-lite-service 3000:3000 -n video-streaming"

echo.
echo Waiting for port forward to establish...
timeout /t 10 /nobreak

echo.
echo 🎯 STEP 7: Test Grafana Access
echo =============================
echo Testing Grafana connection...
curl -s -o nul -w "HTTP Status: %%{http_code}" http://localhost:3000/login

echo.
echo.
echo 🎉 GRAFANA ACCESS INFORMATION
echo ============================
echo URL: http://localhost:3000
echo Username: admin
echo Password: video_admin
echo.
echo Alternative passwords to try:
echo - admin123
echo - admin
echo.
echo 🚨 IMPORTANT: Keep the port-forward window open!
echo.

echo 🎯 Opening Grafana in browser...
start http://localhost:3000

echo.
echo ✅ Setup Complete!
echo.
echo If Grafana doesn't work:
echo 1. Check the port-forward window for errors
echo 2. Try different passwords: admin123 or admin
echo 3. Run this script again
echo.
pause
