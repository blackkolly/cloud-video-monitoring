# 📋 Terraform Deployment Prerequisites Checklist

## 🔧 **Required Software Installation**

### 1. **Terraform** (Latest Version)

- **Download**: https://terraform.io/downloads
- **Verify**: `terraform --version`
- **Required**: v1.5 or higher

### 2. **Azure CLI** (Latest Version)

- **Download**: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
- **Verify**: `az --version`
- **Required**: v2.50 or higher

### 3. **Docker Desktop**

- **Download**: https://www.docker.com/products/docker-desktop
- **Verify**: `docker --version`
- **Required**: For building container images

### 4. **kubectl** (Kubernetes CLI)

- **Install**: `az aks install-cli`
- **Verify**: `kubectl version --client`

### 5. **Git** (For version control)

- **Download**: https://git-scm.com/downloads
- **Verify**: `git --version`

---

## 🔐 **Azure Account Information**

### 1. **Azure Student Account**

- ✅ **Account Status**: Active Azure Student account
- ✅ **Credit Balance**: At least $45 available
- ✅ **Subscription**: Valid Azure subscription

### 2. **Login Credentials**

```bash
# Login to Azure
az login
```

**You'll need**: Azure account email and password

### 3. **Subscription Verification**

```bash
# Check your subscription
az account show
az account list --output table
```

---

## 📧 **Contact Information**

### **Already Configured:**

- ✅ **Email**: kolageneral@yahoo.com
- ✅ **Budget Alerts**: 50%, 80%, 90%
- ✅ **Budget Limit**: $45/month

### **Optional (for SMS alerts):**

- **Phone Number**: +1-XXX-XXX-XXXX (for critical alerts)

---

## 🏗️ **Infrastructure Configuration**

### **Pre-configured Values in `terraform.tfvars`:**

```hcl
# Environment Settings
environment = "dev"
location    = "East US"  # Cheapest Azure region
owner       = "student"
cost_center = "education"

# Budget Control
max_monthly_cost_usd = 45
alert_threshold_percentage = 80

# Kubernetes Configuration
kubernetes_version = "1.27"
node_count = 1
vm_size = "Standard_B2s"  # Budget-optimized

# Database Configuration
postgres_sku = "B_Standard_B1ms"  # Basic tier
postgres_storage_gb = 32

# Container Registry
acr_sku = "Basic"
```

---

## 🚀 **Deployment Steps**

### **Step 1: Environment Check**

```bash
# Navigate to terraform directory
cd terraform/

# Run prerequisite checker
./check-prerequisites.sh
```

### **Step 2: Initialize Terraform**

```bash
# Initialize Terraform (downloads providers)
terraform init
```

### **Step 3: Plan Deployment**

```bash
# Create deployment plan
terraform plan
```

### **Step 4: Review and Deploy**

```bash
# Apply the infrastructure
terraform apply
```

### **Step 5: Configure Kubernetes**

```bash
# Get AKS credentials
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)
```

---

## ⚠️ **Important Information to Confirm**

### **1. Azure Region Preference**

- **Current**: "East US" (cheapest)
- **Alternatives**: "Central US", "West US 2"
- **Consider**: Latency to your location

### **2. Resource Naming**

- **Project**: video-streaming
- **Environment**: dev
- **Resources**: Auto-named with random suffix

### **3. Budget Monitoring**

- **Email**: kolageneral@yahoo.com ✅
- **Alerts**: 50% ($22.50), 80% ($36), 90% ($40.50) ✅
- **Limit**: $45/month ✅

---

## 🔍 **Pre-Deployment Verification**

Run this command to verify everything is ready:

```bash
# Check all prerequisites
cd C:\Users\hp\Desktop\AWS\Kubernetes_Project\cloud-video-network-monitoring\terraform\
./check-prerequisites.sh
```

**Expected Output:**

```
✅ Terraform found
✅ Azure CLI found
✅ Docker found
✅ Docker daemon running
✅ Azure CLI authenticated
✅ VM quota available
🎉 All checks passed! Ready for deployment.
```

---

## 💡 **What You DON'T Need to Provide**

- ❌ Azure subscription ID (auto-detected)
- ❌ Tenant ID (auto-detected)
- ❌ Service principal (uses your login)
- ❌ SSH keys (auto-generated)
- ❌ Database passwords (auto-generated)
- ❌ SSL certificates (not needed for dev)

---

## 🚨 **Emergency Information**

### **If Something Goes Wrong:**

```bash
# Check what's deployed
terraform show

# Destroy everything to stop costs
terraform destroy -auto-approve

# Emergency Azure cleanup
az group delete --name video-streaming-dev-rg --yes --no-wait
```

### **Cost Monitoring:**

```bash
# Check current spending
az consumption usage list --start-date $(date +%Y-%m-01) --end-date $(date +%Y-%m-%d)

# Scale down to save money
kubectl scale deployment --all --replicas=0 -n video-streaming
```

---

## ✅ **Ready to Deploy?**

If you have all the above requirements met, you can start the deployment with:

```bash
cd terraform/
./deploy.sh
```

The script will guide you through each step and provide detailed feedback on progress and any issues encountered.

**Estimated Deployment Time**: 10-15 minutes
**Estimated Monthly Cost**: $40-45 (within your budget)
**Budget Protection**: Active with email alerts
