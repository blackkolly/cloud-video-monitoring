# Quick Azure AKS Deployment Guide (No Terraform)

## 🚀 Simple Deployment - No IaC Required

This guide deploys your video streaming platform directly to Azure AKS using only Azure CLI and kubectl - **no Terraform needed**.

### 📋 Prerequisites

1. **Azure Student Account** with $45 credit
2. **Azure CLI** - [Install here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Docker Desktop** - [Install here](https://www.docker.com/products/docker-desktop)
4. **kubectl** - Install with: `az aks install-cli`

### ⚡ One-Command Deployment

```bash
cd azure-aks/
./deploy-simple.sh
```

That's it! The script handles everything:

- ✅ Creates Azure Resource Group
- ✅ Creates Container Registry
- ✅ Creates AKS Cluster
- ✅ Builds and pushes Docker images
- ✅ Deploys all Kubernetes resources
- ✅ Configures LoadBalancer

### 💰 Cost Monitoring

**Estimated costs:**

- AKS Control Plane: **FREE**
- VM (Standard_B2s): **$30-35/month**
- Storage: **$5-8/month**
- Load Balancer: **$5/month**
- Container Registry: **$5/month**
- **Total: ~$45-53/month**

### 🔍 Monitor Your Deployment

```bash
# Check if everything is running
kubectl get pods -n video-streaming

# Get your application URL
kubectl get svc frontend-service -n video-streaming

# Check logs if issues
kubectl logs -l app=backend-api -n video-streaming
```

### 💡 Cost Optimization

```bash
# Scale down to save money when not using
kubectl scale deployment backend-api --replicas=1 -n video-streaming
kubectl scale deployment frontend --replicas=1 -n video-streaming

# Monitor costs
az consumption usage list --start-date $(date +%Y-%m-01) --end-date $(date +%Y-%m-%d)
```

### 🧹 Clean Up When Done

```bash
# Delete everything to stop all charges
az group delete --name video-streaming-rg --yes --no-wait
```

### 🆘 Troubleshooting

**Common Issues:**

1. **Azure CLI not logged in:**

   ```bash
   az login
   ```

2. **Docker not running:**

   - Start Docker Desktop
   - Ensure Docker daemon is running

3. **kubectl not working:**

   ```bash
   az aks get-credentials --resource-group video-streaming-rg --name video-streaming-aks
   ```

4. **External IP pending:**

   ```bash
   # Wait a few minutes, then check
   kubectl get svc frontend-service -n video-streaming --watch
   ```

5. **Pods not starting:**
   ```bash
   kubectl describe pods -n video-streaming
   kubectl logs [POD-NAME] -n video-streaming
   ```

### 📱 What You Get

After successful deployment:

- 🌐 **Public web interface** for video streaming
- 🎥 **Video upload and playback** functionality
- 📊 **Real-time streaming analytics**
- 🔄 **Auto-scaling** capabilities
- 💾 **Persistent storage** for videos
- 🛡️ **Load balancing** for high availability

### 🎯 Testing Your Platform

1. **Access the frontend:** `http://[EXTERNAL-IP]`
2. **Test API health:** `http://[EXTERNAL-IP]/api/health`
3. **Upload a video** through the web interface
4. **Stream videos** with quality selection

### 📈 Scaling Options

**Scale up for more users:**

```bash
kubectl scale deployment frontend --replicas=3 -n video-streaming
kubectl scale deployment backend-api --replicas=3 -n video-streaming
```

**Scale cluster nodes:**

```bash
az aks scale --resource-group video-streaming-rg --name video-streaming-aks --node-count 2
```

### 🔒 Security Notes

- Default setup uses HTTP (not HTTPS)
- Database passwords are basic (change for production)
- No authentication/authorization (add if needed)
- LoadBalancer exposes public IP
- Budget alerts configured for: kolageneral@yahoo.com

### 🚀 Production Improvements

For production use, consider:

1. **HTTPS/SSL certificates**
2. **Azure Active Directory integration**
3. **Azure Key Vault for secrets**
4. **Azure Monitor for logging**
5. **Azure CDN for video delivery**
6. **Auto-scaling rules**

This deployment gives you a fully functional video streaming platform on Azure AKS without any Infrastructure as Code complexity!
