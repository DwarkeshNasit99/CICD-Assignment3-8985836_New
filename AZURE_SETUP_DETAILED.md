# Azure Configuration Guide - Detailed Steps
## Free Tier Compatible Setup for Assignment 3

This guide provides exact steps for setting up Azure Functions on the **FREE TIER** - no pay-as-you-go required for this assignment.

---

## 💰 Azure Free Tier Limitations & What's Included

### ✅ What's FREE and Sufficient for This Assignment:
- **Azure Functions**: 1,000,000 executions per month
- **Function App**: 1 GB memory usage per month  
- **Storage Account**: 5 GB storage, 20,000 transactions
- **App Service**: 60 CPU minutes per day
- **Bandwidth**: 15 GB outbound data transfer per month

### ❌ What You DON'T Need (Paid Features):
- Premium Function Plans
- Dedicated App Service Plans
- Application Insights (optional)
- Custom domains

**Result**: This assignment will work 100% on Azure Free Tier! 🎉

---

## 🛠️ Step-by-Step Azure Setup

### Step 1: Create Resource Group

```bash
# Using Azure Portal (Recommended for beginners):
1. Login to portal.azure.com
2. Click "Resource groups" 
3. Click "+ Create"
4. Subscription: Your free subscription
5. Resource group name: rg-assignment3-[yourname]
6. Region: East US (or closest to you)
7. Click "Review + create" → "Create"

# Using Azure CLI (Alternative):
az group create --name "rg-assignment3-yourname" --location "eastus"
```

### Step 2: Create Storage Account (Required for Function App)

```bash
# Portal Method:
1. In your resource group, click "+ Create"
2. Search "Storage account" → Select → Create
3. Settings:
   - Storage account name: stassignment3yourname (lowercase, no spaces)
   - Region: Same as resource group
   - Performance: Standard
   - Redundancy: Locally-redundant storage (LRS) - CHEAPEST
   - Other settings: Leave default
4. Click "Review + create" → "Create"

# CLI Method:
az storage account create \
  --name "stassignment3yourname" \
  --resource-group "rg-assignment3-yourname" \
  --location "eastus" \
  --sku "Standard_LRS" \
  --kind "StorageV2"
```

### Step 3: Create Function App (FREE TIER)

```bash
# Portal Method (RECOMMENDED):
1. In resource group, click "+ Create"
2. Search "Function App" → Select → Create

# CRITICAL SETTINGS for FREE TIER:
Basic Settings:
- Function App name: func-assignment3-yourname
- Runtime stack: Node.js
- Version: 18 LTS
- Operating System: Linux (cheaper than Windows)
- Region: Same as resource group

Hosting:
- Plan type: Consumption (Serverless) ← THIS IS THE FREE OPTION!
- Storage account: Select the one you created above

Monitoring:
- Enable Application Insights: No (saves costs)

Networking:
- Enable public access: Yes

3. Click "Review + create" → "Create"

# CLI Method:
az functionapp create \
  --resource-group "rg-assignment3-yourname" \
  --consumption-plan-location "eastus" \
  --runtime "node" \
  --runtime-version "18" \
  --functions-version "4" \
  --name "func-assignment3-yourname" \
  --storage-account "stassignment3yourname" \
  --os-type "Linux"
```

### Step 4: Verify Function App Settings

1. **Go to your Function App in Azure Portal**
2. **Check Configuration → General settings**:
   ```
   ✅ Runtime stack: Node.js
   ✅ Runtime version: ~18
   ✅ Platform: 64 Bit
   ✅ HTTPS Only: On
   ```

3. **Check Configuration → Application settings** (should auto-populate):
   ```
   FUNCTIONS_EXTENSION_VERSION: ~4
   FUNCTIONS_WORKER_RUNTIME: node
   WEBSITE_NODE_DEFAULT_VERSION: ~18
   AzureWebJobsStorage: [connection string to your storage]
   ```

---

## 🔐 Service Principal Setup (For Jenkins Authentication)

### Step 1: Get Your Subscription ID

```bash
# Portal Method:
1. Go to "Subscriptions" in Azure Portal
2. Click your subscription name
3. Copy the "Subscription ID"

# CLI Method:
az account show --query "id" --output tsv
```

### Step 2: Create Service Principal

```bash
# Replace YOUR_SUBSCRIPTION_ID with actual ID
az ad sp create-for-rbac \
  --name "jenkins-assignment3-yourname" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-assignment3-yourname"

# Save this output - you'll need it for Jenkins:
{
  "appId": "12345678-1234-1234-1234-123456789abc",      ← AZURE_CLIENT_ID
  "displayName": "jenkins-assignment3-yourname",
  "password": "abcdefgh-1234-1234-1234-abcdefghijkl",   ← AZURE_CLIENT_SECRET  
  "tenant": "87654321-4321-4321-4321-210987654321"      ← AZURE_TENANT_ID
}
```

### Step 3: Test Service Principal (Optional but Recommended)

```bash
# Test login with service principal
az login --service-principal \
  --username "YOUR_CLIENT_ID" \
  --password "YOUR_CLIENT_SECRET" \
  --tenant "YOUR_TENANT_ID"

# Verify access to your resource group
az group show --name "rg-assignment3-yourname"

# Logout
az logout
```

---

## 🧪 Local Testing Setup (Optional)

### Step 1: Install Azure Functions Core Tools

```bash
# Windows (using npm):
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Linux/macOS:
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt update
sudo apt install azure-functions-core-tools-4
```

### Step 2: Test Locally

```bash
# Copy the template file
cp local.settings.json.template local.settings.json

# Start local development server
npm start
# or
func start

# Test the function
curl http://localhost:7071/api/hello
```

---

## 📝 Jenkins Credentials Configuration

### Required Credentials for Jenkins:

```
Credential ID: azure-client-id
Type: Secret text
Value: [appId from service principal output]

Credential ID: azure-client-secret  
Type: Secret text
Value: [password from service principal output]

Credential ID: azure-tenant-id
Type: Secret text  
Value: [tenant from service principal output]

Credential ID: azure-subscription-id
Type: Secret text
Value: [your subscription ID]

Credential ID: azure-resource-group
Type: Secret text
Value: rg-assignment3-yourname

Credential ID: azure-function-app-name
Type: Secret text
Value: func-assignment3-yourname
```

---

## 🔍 Deployment Verification Commands

### Check Function App Status:
```bash
az functionapp show \
  --resource-group "rg-assignment3-yourname" \
  --name "func-assignment3-yourname" \
  --query "{name:name,state:state,defaultHostName:defaultHostName}"
```

### Get Function URL:
```bash
az functionapp function show \
  --resource-group "rg-assignment3-yourname" \
  --name "func-assignment3-yourname" \
  --function-name "httpTrigger" \
  --query "invokeUrlTemplate" \
  --output tsv
```

### Test Function:
```bash
# Replace with your actual function URL
curl "https://func-assignment3-yourname.azurewebsites.net/api/hello"
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Storage account name not available"
**Solution**: Use a more unique name
```bash
# Try: stassignment3yourname20241201
# Or: sta + yourfirstname + yourlastname + 3digits
```

### Issue 2: "Function app name not available"  
**Solution**: Use a more unique name
```bash
# Try: func-assignment3-yourname-001
# Or: func-a3-yourfirstname-yourlastname
```

### Issue 3: "Deployment fails with 'Unauthorized'"
**Solution**: Verify service principal permissions
```bash
# Re-create service principal with correct scope
az ad sp create-for-rbac \
  --name "jenkins-assignment3-new" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### Issue 4: "Function returns 500 error"
**Solution**: Check function logs
```bash
az functionapp logs tail \
  --resource-group "rg-assignment3-yourname" \
  --name "func-assignment3-yourname"
```

---

## 💡 Important Notes for Assignment Submission

### ✅ What Your Function URL Should Look Like:
```
https://func-assignment3-yourname.azurewebsites.net/api/hello
```

### ✅ Expected Response Format:
```json
{
  "message": "Hello, World! This Azure Function was deployed using Jenkins CI/CD Pipeline.",
  "timestamp": "2024-12-01T10:30:00.000Z",
  "environment": "production",
  "nodeVersion": "v18.x.x"
}
```

### ✅ With Name Parameter:
```
https://func-assignment3-yourname.azurewebsites.net/api/hello?name=YourName

Response:
{
  "message": "Hello, YourName! This Azure Function was deployed using Jenkins CI/CD Pipeline.",
  "timestamp": "2024-12-01T10:30:00.000Z",
  "environment": "production", 
  "nodeVersion": "v18.x.x"
}
```

---

## 💰 Cost Monitoring (Stay Within Free Tier)

1. **Monitor Usage**:
   - Azure Portal → Cost Management + Billing
   - Set up billing alerts at $1, $5, $10

2. **Resource Cleanup** (After Assignment):
   ```bash
   # Delete entire resource group (everything inside it)
   az group delete --name "rg-assignment3-yourname" --yes --no-wait
   ```

3. **Free Tier Limits to Watch**:
   - Function executions: < 1M per month
   - Storage transactions: < 20,000 per month
   - Outbound data: < 15 GB per month

**For this assignment, you'll use less than 1% of these limits! 🎉**

---

## 📋 Pre-Submission Checklist

- [ ] Resource group created with correct name
- [ ] Storage account created (Standard_LRS)
- [ ] Function app created (Consumption plan)
- [ ] Service principal created with proper permissions
- [ ] Function app accessible via URL
- [ ] Function returns expected JSON response
- [ ] All credentials added to Jenkins
- [ ] Pipeline runs successfully end-to-end

**You're ready to proceed with the Jenkins setup! 🚀**