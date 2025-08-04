# CI/CD Pipeline Setup Guide
## Jenkins + GitHub + Azure Functions

This guide provides step-by-step instructions to set up the complete CI/CD pipeline for Azure Functions using Jenkins and GitHub.

## 📋 Prerequisites

### Accounts Required
- **GitHub Account**: For source code repository
- **Azure Account**: Free tier is sufficient for this assignment
- **Local Machine**: Windows/Linux/macOS for Jenkins installation

### Software Requirements
- Java 11+ (for Jenkins)
- Node.js 18+ (for Azure Functions)
- Git
- Azure CLI

---

## 🎯 Part 1: Azure Function App Setup

### Step 1: Create Azure Function App

1. **Login to Azure Portal**
   - Go to [portal.azure.com](https://portal.azure.com)
   - Sign in with your Azure account

2. **Create Function App**
   ```bash
   # Option 1: Using Azure Portal
   1. Click "Create a resource"
   2. Search for "Function App"
   3. Click "Create"
   
   # Option 2: Using Azure CLI (if you have it installed)
   az group create --name "rg-assignment3" --location "East US"
   az functionapp create \
     --resource-group "rg-assignment3" \
     --consumption-plan-location "East US" \
     --runtime node \
     --runtime-version 18 \
     --functions-version 4 \
     --name "func-assignment3-yourname" \
     --storage-account "stassignment3yourname"
   ```

3. **Function App Settings**
   - **Subscription**: Your Azure subscription
   - **Resource Group**: Create new (e.g., `rg-assignment3-yourname`)
   - **Function App name**: Unique name (e.g., `func-assignment3-yourname`)
   - **Runtime stack**: Node.js
   - **Version**: 18 LTS
   - **Operating System**: Linux (recommended)
   - **Plan type**: Consumption (Serverless) - FREE TIER
   - **Storage**: Create new storage account

4. **Note Important Details**
   ```
   ✅ Function App Name: func-assignment3-yourname
   ✅ Resource Group: rg-assignment3-yourname
   ✅ Subscription ID: (copy from Azure portal)
   ```

### Step 2: Create Service Principal for Jenkins

1. **Using Azure CLI**
   ```bash
   # Install Azure CLI if not installed
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Login to Azure
   az login
   
   # Create service principal
   az ad sp create-for-rbac --name "jenkins-assignment3" --role contributor \
     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
   ```

2. **Save the Output** (You'll need these values for Jenkins):
       ```json
    {
      "appId": "your-client-id",
      "displayName": "jenkins-assignment3",
      "password": "your-client-secret",
      "tenant": "your-tenant-id"
    }
    ```

---

## 🛠️ Part 2: Jenkins Installation & Setup

### Step 1: Install Jenkins (Ubuntu/Debian)

```bash
# Run the setup script
chmod +x scripts/setup-jenkins.sh
./scripts/setup-jenkins.sh
```

### Step 2: Install Jenkins (Windows)

1. **Download Jenkins**
   - Go to [jenkins.io/download](https://www.jenkins.io/download/)
   - Download Windows installer

2. **Install Java 11**
   - Download from [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
   - Or use OpenJDK

3. **Install Node.js**
   - Download from [nodejs.org](https://nodejs.org/)
   - Choose LTS version 18.x

4. **Install Azure CLI**
   - Download from [Microsoft](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)

### Step 3: Initial Jenkins Configuration

1. **Access Jenkins**
   - Open browser: `http://localhost:8080`
   - Enter initial admin password (shown in terminal or found at `/var/lib/jenkins/secrets/initialAdminPassword`)

2. **Install Plugins**
   - Choose "Install suggested plugins"
   - Install additional plugins:
     - GitHub Plugin
     - Pipeline Plugin
     - NodeJS Plugin
     - Credentials Plugin
     - Azure CLI Plugin (if available)

3. **Create Admin User**
   - Create your admin account
   - Save Jenkins URL

### Step 4: Configure Jenkins Tools

1. **Configure Node.js**
   - Go to: `Manage Jenkins` → `Global Tool Configuration`
   - Add NodeJS installation:
     - Name: `Node18`
     - Version: `18.x.x`
     - Install automatically: ✅

2. **Configure Git**
   - Usually auto-detected
   - Verify in `Global Tool Configuration`

### Step 5: Add Azure Credentials

1. **Go to Credentials**
   - `Manage Jenkins` → `Manage Credentials` → `System` → `Global credentials`

2. **Add Service Principal Credentials**
   
   **Add these credentials (one by one):**
   
   ```
   Credential 1:
   - Kind: Secret text
   - Secret: your-client-id-from-service-principal
   - ID: azure-client-id
   - Description: Azure Client ID
   
   Credential 2:
   - Kind: Secret text  
   - Secret: your-client-secret-from-service-principal
   - ID: azure-client-secret
   - Description: Azure Client Secret
   
   Credential 3:
   - Kind: Secret text
   - Secret: your-tenant-id-from-service-principal  
   - ID: azure-tenant-id
   - Description: Azure Tenant ID
   
   Credential 4:
   - Kind: Secret text
   - Secret: your-subscription-id
   - ID: azure-subscription-id
   - Description: Azure Subscription ID
   
   Credential 5:
   - Kind: Secret text
   - Secret: rg-assignment3-yourname
   - ID: azure-resource-group
   - Description: Azure Resource Group
   
   Credential 6:
   - Kind: Secret text
   - Secret: func-assignment3-yourname
   - ID: azure-function-app-name
   - Description: Azure Function App Name
   ```

---

## 🔗 Part 3: GitHub Repository Setup

### Step 1: Create Repository

1. **Create New Repository**
   - Go to [github.com](https://github.com)
   - Click "New repository"
   - Name: `assignment3-cicd-yourname` (replace with your name/ID)
   - Description: "Jenkins CI/CD Pipeline for Azure Functions - Assignment 3"
   - Public repository
   - Don't initialize with README (we'll push existing code)

### Step 2: Push Code to GitHub

```bash
# Initialize git in your project directory
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Azure Function with CI/CD pipeline"

# Add remote repository
git remote add origin https://github.com/yourusername/assignment3-cicd-yourname.git

# Push to GitHub
git push -u origin main
```

### Step 3: Create GitHub Personal Access Token

1. **Generate Token**
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Click "Generate new token (classic)"
   - Scopes needed:
     - `repo` (Full control of private repositories)
     - `workflow` (Update GitHub Action workflows)

2. **Add Token to Jenkins**
   - `Manage Jenkins` → `Manage Credentials` → `System` → `Global credentials`
   - Add Credential:
     - Kind: Username with password
     - Username: your-github-username
     - Password: your-personal-access-token
     - ID: github-credentials
     - Description: GitHub Personal Access Token

---

## 🚀 Part 4: Create Jenkins Pipeline

### Step 1: Create New Pipeline Job

1. **New Item**
   - Click "New Item" in Jenkins
   - Enter name: `Azure-Function-CICD-Pipeline`
   - Select "Pipeline"
   - Click "OK"

### Step 2: Configure Pipeline

1. **General Settings**
   - Description: "CI/CD Pipeline for Azure Functions - Assignment 3"
   - GitHub project URL: `https://github.com/yourusername/assignment3-cicd-yourname`

2. **Build Triggers**
   - ✅ GitHub hook trigger for GITScm polling
   - ✅ Poll SCM: `H/5 * * * *` (optional, polls every 5 minutes)

3. **Pipeline Configuration**
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/yourusername/assignment3-cicd-yourname.git`
   - Credentials: Select your GitHub credentials
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

### Step 3: Configure GitHub Webhook (Optional but Recommended)

1. **In GitHub Repository**
   - Go to Settings → Webhooks
   - Click "Add webhook"
   - Payload URL: `http://your-jenkins-url:8080/github-webhook/`
   - Content type: `application/json`
   - Events: "Just the push event"
   - Active: ✅

---

## 🧪 Part 5: Testing the Pipeline

### Step 1: Run Initial Build

1. **Manual Trigger**
   - Go to your Jenkins pipeline
   - Click "Build Now"
   - Monitor the console output

### Step 2: Test Automatic Trigger

```bash
# Make a small change to trigger the pipeline
echo "// Pipeline test" >> src/functions/httpTrigger.js
git add .
git commit -m "Test: Trigger CI/CD pipeline"
git push origin main
```

### Step 3: Verify Deployment

1. **Check Jenkins Pipeline**
   - All stages should be green ✅
   - Deploy stage should show function URL

2. **Test Azure Function**
   - Copy the function URL from Jenkins output
   - Test in browser: `https://your-function-url/api/hello`
   - Expected response: JSON with "Hello, World!" message

---

## 🔍 Part 6: Troubleshooting Common Issues

### Jenkins Issues

```bash
# Check Jenkins service status
sudo systemctl status jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Restart Jenkins if needed
sudo systemctl restart jenkins
```

### Azure CLI Issues

```bash
# Check Azure CLI installation
az --version

# Login to Azure
az login

# Verify subscription
az account show
```

### Permission Issues

```bash
# Add user to Jenkins group (Linux)
sudo usermod -aG jenkins $USER

# Fix Jenkins permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins/
```

### Node.js Issues

```bash
# Check Node.js version
node --version
npm --version

# Clear npm cache if needed
npm cache clean --force
```

---

## 📝 Assignment Submission Checklist

### ✅ Required Deliverables

1. **GitHub Repository URL**
   - Repository contains all source code
   - Includes Jenkinsfile
   - Has proper commit history

2. **Jenkins Pipeline Screenshots**
   - Screenshot of successful pipeline run
   - Console output showing all stages passed
   - Pipeline configuration screenshot

3. **Azure Function URL**
   - Working function URL
   - Returns proper JSON response
   - Accessible from internet

4. **Test Results**
   - At least 3 test cases implemented
   - All tests passing in Jenkins
   - Test coverage report (optional)

### 📸 Screenshots to Take

1. Jenkins dashboard with successful build
2. Pipeline stage view (all green)
3. Console output of successful deployment
4. Azure Function response in browser
5. GitHub repository with code
6. Test results in Jenkins

---

## 🆘 Support & Resources

### Documentation
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)

### Common Commands Reference

```bash
# Jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Azure CLI
az login
az account list
az functionapp list
az functionapp logs tail --name <function-name> --resource-group <rg-name>

# Node.js
npm install
npm test
npm start

# Git
git status
git add .
git commit -m "message"
git push origin main
```

### Cost Information
- **Azure Functions**: FREE tier includes 1 million executions per month
- **Storage Account**: FREE tier includes 5GB storage
- **Jenkins**: Free if running locally
- **GitHub**: Free for public repositories

---

## ✅ Final Verification

Before submitting, verify:

1. ✅ Azure Function App is created and accessible
2. ✅ Jenkins is installed and configured
3. ✅ GitHub repository contains all code
4. ✅ Pipeline runs successfully end-to-end
5. ✅ All 3+ test cases pass
6. ✅ Function is deployed and returns correct response
7. ✅ Screenshots are taken for submission

**Good luck with your assignment! 🚀**