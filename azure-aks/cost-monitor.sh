#!/bin/bash

# Cost monitoring and management script for Azure Student Account

RESOURCE_GROUP="video-streaming-rg"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "💰 Azure Cost Monitoring for Video Streaming Platform"
echo "=================================================="

# Check current spending
echo "📊 Current Month Spending:"
CURRENT_COSTS=$(az consumption usage list \
    --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
    --end-date $(date +%Y-%m-%d) \
    --query '[].pretaxCost' -o tsv | awk '{sum += $1} END {print sum}')

echo "Current spending: $${CURRENT_COSTS:-0}"
echo "Remaining budget: $$(echo "45 - ${CURRENT_COSTS:-0}" | bc)"

# Check resource costs
echo ""
echo "🏗️  Current Resources:"
az resource list --resource-group $RESOURCE_GROUP --query '[].{Name:name, Type:type, Location:location}' -o table

# Scale down resources to save money
echo ""
echo "💸 Cost Optimization Options:"
echo "1. Scale down deployments (saves ~30%)"
echo "2. Use spot instances (saves ~80%)"
echo "3. Stop during nights/weekends"
echo "4. Delete unused storage"

read -p "Do you want to scale down to save money? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🔽 Scaling down resources..."
    kubectl scale deployment backend-api --replicas=1 -n video-streaming
    kubectl scale deployment frontend --replicas=1 -n video-streaming
    echo "✅ Scaled down to save ~$10-15/month"
fi

# Set up budget alerts
read -p "Set up budget alerts? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🚨 Setting up budget alerts..."
    # This would require additional Azure CLI budget commands
    echo "💡 Manually set up budget alerts in Azure Portal:"
    echo "   1. Go to Cost Management + Billing"
    echo "   2. Create budget: $45"
    echo "   3. Set alerts at: $30, $40, $45"
fi

echo ""
echo "📱 Monitoring Commands:"
echo "Check costs: az consumption usage list --start-date $(date +%Y-%m-01) --end-date $(date +%Y-%m-%d)"
echo "Check resources: az resource list --resource-group $RESOURCE_GROUP"
echo "Emergency cleanup: az group delete --name $RESOURCE_GROUP --yes --no-wait"
