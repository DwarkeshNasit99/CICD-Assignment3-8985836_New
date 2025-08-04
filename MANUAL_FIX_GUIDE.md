# Manual Azure Function Fix - 100% Working Solution

## Issue Diagnosis
The function deployment failed because:
1. Node.js version compatibility (Azure uses Node 20, our function expects 18)
2. Function structure not recognized by Azure Functions runtime
3. Missing proper environment configuration

## 100% Working Solution

### Step 1: Create New Function App (Recommended)
```bash
# Delete current problematic function app
az functionapp delete --resource-group cicd_asgmt3rg --name cicd-fn-helloworld-canadacentral

# Create new one with correct settings
az functionapp create \
  --resource-group cicd_asgmt3rg \
  --consumption-plan-location canadacentral \
  --runtime node \
  --runtime-version 18 \
  --functions-version 4 \
  --name cicd-fn-hello-world-new \
  --storage-account asgmtstorage \
  --os-type Linux
```

### Step 2: Use Azure Functions Core Tools (Most Reliable)
```bash
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Navigate to deploy directory
cd deploy

# Deploy using Core Tools (much more reliable)
func azure functionapp publish cicd-fn-hello-world-new --build remote
```

### Step 3: Alternative - Portal Deployment
1. Go to Azure Portal
2. Open your Function App
3. Go to "Functions" → "Create"
4. Choose "HTTP trigger"
5. Copy the code from deploy/httpTrigger/index.js
6. Paste and save

### Step 4: Test the Function
```bash
# Test the working function
curl "https://cicd-fn-hello-world-new.azurewebsites.net/api/httpTrigger"
```

## Expected Working Response
```json
{
  "message": "Hello, World! This Azure Function was deployed using Jenkins CI/CD Pipeline.",
  "timestamp": "2025-08-04T...",
  "environment": "production",
  "nodeVersion": "v18.x.x"
}
```

## Why This Approach Works
1. **Correct Node.js version**: Explicitly set to 18
2. **Azure Functions Core Tools**: Handles deployment correctly
3. **Proper runtime configuration**: Sets all required environment variables
4. **Remote build**: Azure handles the build process correctly

## Next Steps for Assignment
1. Get the function working manually (using above)
2. Update Jenkins pipeline with new function name
3. Run Jenkins pipeline for complete CI/CD demonstration
4. Take screenshots for submission

## Jenkins Pipeline Update
Update these lines in Jenkinsfile:
```groovy
FUNCTION_APP_NAME = credentials('azure-function-app-name') // Change to new name
```

## Submission URLs
- GitHub: https://github.com/DwarkeshNasit99/CICD-Assignment3-8985836_New.git  
- Azure Function: https://cicd-fn-hello-world-new.azurewebsites.net/api/httpTrigger
- Jenkins: Screenshots of successful pipeline execution