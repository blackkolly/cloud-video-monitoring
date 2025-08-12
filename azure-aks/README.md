# Azure AKS Video Streaming Platform - Student Budget Deployment

## 💰 Cost Optimization for $45 Azure Student Account

This deployment is specifically optimized for Azure Student accounts with limited budget.

### 📊 Estimated Monthly Costs
- **AKS Control Plane**: FREE (managed by Azure)
- **Standard_B2s Node**: $30-35/month (2 vCPU, 4GB RAM)
- **Managed SSD Storage**: $5-8/month (30GB total)
- **Load Balancer**: $5/month
- **Container Registry**: $5/month (Basic tier)
- **Total**: ~$45-53/month ⚠️ (Close to budget limit)

### 🚀 Quick Deployment Steps

#### Prerequisites
1. **Azure CLI** installed and configured
2. **Docker** installed
3. **kubectl** installed
4. **Azure Student Account** with $45 credit

#### 1. Login to Azure
```bash
az login
az account set --subscription "Your Student Subscription"
```

#### 2. Run Deployment Script
```bash
cd azure-aks/
chmod +x deploy-to-aks.sh
./deploy-to-aks.sh
```

#### 3. Monitor Deployment
```bash
# Check pods status
kubectl get pods -n video-streaming

# Check services
kubectl get svc -n video-streaming

# Get external IP
kubectl get svc frontend-service -n video-streaming
```

### 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `1-namespace.yaml` | Creates namespace and config |
| `2-postgres.yaml` | PostgreSQL database |
| `3-redis.yaml` | Redis cache |
| `4-backend.yaml` | FastAPI backend service |
| `5-frontend.yaml` | React frontend with LoadBalancer |

### 📱 Accessing Your Application

After deployment:
1. Get the external IP: `kubectl get svc frontend-service -n video-streaming`
2. Access frontend: `http://[EXTERNAL-IP]`
3. Access API: `http://[EXTERNAL-IP]/api`

### 💡 Cost Optimization Tips

#### Reduce Costs:
```bash
# Scale down to save money when not using
kubectl scale deployment backend-api --replicas=1 -n video-streaming
kubectl scale deployment frontend --replicas=1 -n video-streaming

# Use spot instances (advanced)
# Add to AKS creation: --enable-cluster-autoscaler --min-count 1 --max-count 2
```

#### Monitor Costs:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n video-streaming

# Azure cost analysis
az consumption usage list --start-date 2025-08-01 --end-date 2025-08-31
```

### 🧹 Clean Up to Save Money

When done testing:
```bash
# Delete everything to stop charges
az group delete --name video-streaming-rg --yes --no-wait
```

### ⚠️ Budget Warnings

- **Monitor daily**: Check Azure portal for cost alerts
- **Set budget alerts**: Create alerts at $30, $40, $45
- **Cleanup regularly**: Delete unused resources
- **Use free tiers**: PostgreSQL flexible server has free tier option

### 🔄 Alternative: Cheaper Local Development

If budget is too tight, consider:
```bash
# Use local development instead
docker-compose -f docker-compose.simple.yml up
```

### 📞 Support

Contact: kolageneral@yahoo.com

If you encounter issues:
1. Check logs: `kubectl logs -l app=backend-api -n video-streaming`
2. Check events: `kubectl get events -n video-streaming`
3. Verify images: `kubectl describe pod [POD-NAME] -n video-streaming`

### 🎯 Next Steps After Deployment

1. **Test upload functionality**
2. **Configure domain** (optional)
3. **Set up monitoring** with Azure Monitor
4. **Implement CI/CD** with GitHub Actions
5. **Add SSL certificate** for HTTPS
