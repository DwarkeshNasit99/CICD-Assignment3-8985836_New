# Assignment 3 Execution Checklist
## Step-by-Step Completion Guide

Follow this checklist in order to complete the assignment successfully. Check off each item as you complete it.

---

## 🎯 Phase 1: Azure Setup (30 minutes)

### Step 1.1: Azure Account Verification
- [ ] Login to [portal.azure.com](https://portal.azure.com)
- [ ] Verify you have an active Azure subscription
- [ ] Confirm you're using **Free Tier** (no credit card required for this assignment)

### Step 1.2: Create Azure Resources
- [ ] **Create Resource Group**:
  - Name: `rg-assignment3-[yourname]`
  - Location: East US (or closest to you)
- [ ] **Create Storage Account**:
  - Name: `stassignment3[yourname]` (must be unique, lowercase)
  - Type: Standard_LRS (cheapest option)
  - Same location as resource group
- [ ] **Create Function App**:
  - Name: `func-assignment3-[yourname]` (must be unique)
  - Runtime: Node.js 18 LTS
  - Operating System: Linux
  - Plan: **Consumption (Serverless)** ← FREE TIER
  - Storage: Use the storage account created above

### Step 1.3: Create Service Principal
- [ ] **Install Azure CLI** (if not installed):
  ```bash
  # Windows: Download from Microsoft website
  # Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```
- [ ] **Login to Azure CLI**:
  ```bash
  az login
  ```
- [ ] **Get Subscription ID**:
  ```bash
  az account show --query "id" --output tsv
  # Copy this ID - you'll need it
  ```
- [ ] **Create Service Principal**:
  ```bash
  az ad sp create-for-rbac --name "jenkins-assignment3-[yourname]" --role contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
  ```
- [ ] **Save Service Principal Output** (you'll need these values):
  ```
  appId: _________________ (AZURE_CLIENT_ID)
  password: _____________ (AZURE_CLIENT_SECRET)
  tenant: _______________ (AZURE_TENANT_ID)
  ```

### Step 1.4: Verify Azure Resources
- [ ] Function App shows "Running" status in Azure Portal
- [ ] Resource group contains all 3 resources (RG, Storage, Function App)
- [ ] Function App URL is accessible: `https://func-assignment3-[yourname].azurewebsites.net`

---

## 🛠️ Phase 2: Jenkins Setup (45 minutes)

### Step 2.1: Install Prerequisites (Windows)
- [ ] **Install Java 11**:
  - Download from [adoptium.net](https://adoptium.net/)
  - Verify: `java -version`
- [ ] **Install Node.js 18**:
  - Download from [nodejs.org](https://nodejs.org/)
  - Verify: `node --version` and `npm --version`
- [ ] **Install Git for Windows**:
  - Download from [git-scm.com](https://git-scm.com/download/win)
  - Verify: `git --version`

### Step 2.2: Install Jenkins
- [ ] **Download Jenkins LTS**:
  - From [jenkins.io/download](https://www.jenkins.io/download/)
  - Run the Windows installer
- [ ] **Complete Initial Setup**:
  - Get initial password: `type "C:\ProgramData\Jenkins\.jenkins\secrets\initialAdminPassword"`
  - Access Jenkins: [http://localhost:8080](http://localhost:8080)
  - Install suggested plugins
  - Create admin user account

### Step 2.3: Install Jenkins Plugins
- [ ] Go to: Manage Jenkins → Manage Plugins → Available
- [ ] Install these plugins:
  - [ ] GitHub Plugin
  - [ ] NodeJS Plugin
  - [ ] Pipeline Plugin (usually pre-installed)
  - [ ] Workspace Cleanup Plugin
- [ ] Restart Jenkins after installation

### Step 2.4: Configure Jenkins Tools
- [ ] **Configure Node.js**:
  - Manage Jenkins → Global Tool Configuration
  - Add NodeJS: Name = `Node18`, Install automatically, Version = 18.x
- [ ] **Verify Git Configuration**:
  - Should auto-detect Git installation

### Step 2.5: Add Jenkins Credentials
- [ ] Go to: Manage Jenkins → Manage Credentials → System → Global credentials
- [ ] Add these 6 credentials (Secret text type):

| ID | Description | Value |
|---|---|---|
| `azure-client-id` | Azure Client ID | [appId from service principal] |
| `azure-client-secret` | Azure Client Secret | [password from service principal] |
| `azure-tenant-id` | Azure Tenant ID | [tenant from service principal] |
| `azure-subscription-id` | Azure Subscription ID | [your subscription ID] |
| `azure-resource-group` | Resource Group | `rg-assignment3-[yourname]` |
| `azure-function-app-name` | Function App Name | `func-assignment3-[yourname]` |

---

## 📂 Phase 3: GitHub Repository Setup (15 minutes)

### Step 3.1: Create GitHub Repository
- [ ] **Create new repository** on GitHub:
  - Name: `assignment3-cicd-[yourname]`
  - Description: "Jenkins CI/CD Pipeline for Azure Functions - Assignment 3"
  - Public repository
  - Don't initialize with README

### Step 3.2: Setup Local Git Repository
- [ ] **Initialize git** in your project directory:
  ```bash
  git init
  git add .
  git commit -m "Initial commit: Azure Function with CI/CD pipeline"
  git remote add origin https://github.com/yourusername/assignment3-cicd-[yourname].git
  git push -u origin main
  ```

### Step 3.3: Create GitHub Personal Access Token
- [ ] Go to: GitHub → Settings → Developer settings → Personal access tokens
- [ ] Generate new token (classic)
- [ ] Scopes: `repo`, `workflow`
- [ ] **Copy the token** (you can't see it again!)

### Step 3.4: Add GitHub Credentials to Jenkins
- [ ] Jenkins: Manage Jenkins → Manage Credentials → Global credentials
- [ ] Add credential:
  - Kind: Username with password
  - Username: your-github-username
  - Password: your-personal-access-token
  - ID: `github-credentials`

---

## 🚀 Phase 4: Create Jenkins Pipeline (20 minutes)

### Step 4.1: Create Pipeline Job
- [ ] Jenkins Dashboard → New Item
- [ ] Name: `Azure-Function-CICD-Pipeline`
- [ ] Type: Pipeline
- [ ] Click OK

### Step 4.2: Configure Pipeline
- [ ] **General**:
  - Description: "CI/CD Pipeline for Azure Functions - Assignment 3"
  - GitHub project URL: `https://github.com/yourusername/assignment3-cicd-[yourname]`
- [ ] **Build Triggers**:
  - ✅ GitHub hook trigger for GITScm polling
- [ ] **Pipeline**:
  - Definition: Pipeline script from SCM
  - SCM: Git
  - Repository URL: `https://github.com/yourusername/assignment3-cicd-[yourname].git`
  - Credentials: [select your GitHub credentials]
  - Branch: `*/main`
  - Script Path: `Jenkinsfile`
- [ ] **Save** the configuration

---

## 🧪 Phase 5: Test Everything (30 minutes)

### Step 5.1: Run Initial Pipeline Build
- [ ] **Trigger first build**:
  - Go to your pipeline job
  - Click "Build Now"
  - Monitor console output
- [ ] **Verify all stages pass**:
  - [ ] ✅ Checkout stage
  - [ ] ✅ Build stage (npm install)
  - [ ] ✅ Test stage (5 tests pass)
  - [ ] ✅ Package stage (zip created)
  - [ ] ✅ Deploy stage (deployed to Azure)
  - [ ] ✅ Verify stage (function accessible)

### Step 5.2: Test Deployed Function
- [ ] **Get Function URL** from Jenkins console output
- [ ] **Test in browser**:
  - URL: `https://func-assignment3-[yourname].azurewebsites.net/api/hello`
  - Expected: JSON response with "Hello, World!" message
- [ ] **Test with parameter**:
  - URL: `https://func-assignment3-[yourname].azurewebsites.net/api/hello?name=YourName`
  - Expected: Personalized greeting

### Step 5.3: Test Automatic Trigger
- [ ] **Make a small change** to trigger pipeline:
  ```bash
  echo "// Test automatic trigger" >> src/functions/httpTrigger.js
  git add .
  git commit -m "Test: Trigger CI/CD pipeline automatically"
  git push origin main
  ```
- [ ] **Verify pipeline triggers automatically**
- [ ] **Verify all stages pass again**

---

## 📸 Phase 6: Capture Evidence for Submission (15 minutes)

### Step 6.1: Take Screenshots
- [ ] **Jenkins Dashboard** with successful build history
- [ ] **Pipeline Stage View** showing all stages green
- [ ] **Console Output** of successful build (especially deployment logs)
- [ ] **Azure Function Response** in browser (both default and with name parameter)
- [ ] **GitHub Repository** showing all code files
- [ ] **Test Results** in Jenkins (if visible in UI)

### Step 6.2: Document URLs
- [ ] **GitHub Repository URL**: `https://github.com/yourusername/assignment3-cicd-[yourname]`
- [ ] **Jenkins Job URL**: `http://localhost:8080/job/Azure-Function-CICD-Pipeline/` (or screenshot if not public)
- [ ] **Azure Function URL**: `https://func-assignment3-[yourname].azurewebsites.net/api/hello`

### Step 6.3: Verify Test Requirements
- [ ] **Minimum 3 test cases**: ✅ (You have 5 test cases)
- [ ] **Tests check HTTP response**: ✅
- [ ] **Tests check response code (200)**: ✅
- [ ] **Tests check response content**: ✅

---

## 📋 Phase 7: Final Verification (10 minutes)

### Step 7.1: Complete Assignment Requirements Check
- [ ] **Jenkins Setup (3%)**:
  - [ ] Local Jenkins installation working
  - [ ] GitHub integration configured
  - [ ] Pipeline configuration complete
- [ ] **Pipeline Stages (3%)**:
  - [ ] Build stage functions correctly
  - [ ] Test stage executes all tests
  - [ ] Deploy stage deploys to Azure successfully
- [ ] **Test Cases (2%)**:
  - [ ] At least 3 test cases (you have 5)
  - [ ] Tests execute during Test stage
  - [ ] All tests passing
- [ ] **Azure Deployment (2%)**:
  - [ ] Function deployed successfully
  - [ ] Function publicly accessible
  - [ ] Function returns expected response

### Step 7.2: Final Function Test
- [ ] **Test all endpoints one more time**:
  ```bash
  # Basic test
  curl "https://func-assignment3-[yourname].azurewebsites.net/api/hello"
  
  # With parameter test
  curl "https://func-assignment3-[yourname].azurewebsites.net/api/hello?name=Professor"
  ```
- [ ] **Verify JSON response format**:
  ```json
  {
    "message": "Hello, World! This Azure Function was deployed using Jenkins CI/CD Pipeline.",
    "timestamp": "2024-12-01T...",
    "environment": "production",
    "nodeVersion": "v18.x.x"
  }
  ```

---

## 🎉 Submission Ready Checklist

### ✅ All Required Deliverables:
- [ ] **GitHub Repository URL** with all source code
- [ ] **Jenkins Screenshots** showing successful pipeline
- [ ] **Azure Function URL** that works and returns proper response
- [ ] **Documentation** of the setup process (optional but impressive)

### ✅ Bonus Points Opportunities:
- [ ] More than 3 test cases (you have 5) ✨
- [ ] Comprehensive error handling in pipeline ✨
- [ ] Integration tests for deployed function ✨
- [ ] Detailed logging and monitoring ✨
- [ ] Professional project structure ✨

---

## 🆘 Troubleshooting Quick Reference

### Common Issues & Solutions:

**Jenkins won't start**:
```powershell
# Restart Jenkins service
Restart-Service -Name "Jenkins"
```

**Azure CLI login fails**:
```bash
# Try device login
az login --use-device-code
```

**Pipeline fails at Deploy stage**:
- Check Azure credentials in Jenkins
- Verify Service Principal permissions
- Check Resource Group and Function App names

**Function URL returns 404**:
- Wait 2-3 minutes after deployment
- Check function name in Jenkinsfile matches actual function
- Verify deployment completed successfully

**Tests fail locally**:
```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
npm test
```

---

## ⏱️ Estimated Time Breakdown

| Phase | Time | Status |
|-------|------|--------|
| Azure Setup | 30 min | ⭐ Critical |
| Jenkins Installation | 45 min | ⭐ Critical |
| GitHub Setup | 15 min | ⭐ Critical |
| Pipeline Creation | 20 min | ⭐ Critical |
| Testing & Verification | 30 min | ⭐ Critical |
| Documentation & Screenshots | 15 min | ⭐ Critical |
| **Total** | **2.5-3 hours** | |

---

## 🎯 Success Criteria

You've successfully completed the assignment when:

1. ✅ Jenkins pipeline runs automatically on GitHub push
2. ✅ All 5 test cases pass in the CI/CD pipeline
3. ✅ Azure Function is deployed and publicly accessible
4. ✅ Function returns proper JSON response
5. ✅ You have screenshots showing successful execution
6. ✅ GitHub repository contains all required code

**🎉 CONGRATULATIONS! Your CI/CD pipeline is complete! 🎉**

**Instructor Submission**: Provide the 3 URLs (GitHub, Jenkins screenshots, Azure Function) with evidence of successful execution.