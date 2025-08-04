# Jenkins Setup Guide for Windows
## Complete Installation & Configuration for Azure Functions CI/CD

This guide provides step-by-step instructions for installing and configuring Jenkins on Windows 10/11 for the Azure Functions CI/CD assignment.

---

## 📋 Prerequisites

### Required Software (we'll install these):
- Java 11 or 17 (for Jenkins)
- Jenkins LTS
- Node.js 18+ (for Azure Functions)
- Git for Windows
- Azure CLI
- PowerShell (built-in on Windows)

---

## ☕ Step 1: Install Java

### Method 1: Download from Oracle/OpenJDK (Recommended)

1. **Download OpenJDK 11**:
   - Go to [https://adoptium.net/](https://adoptium.net/)
   - Select: OpenJDK 11 (LTS) → Windows → x64 → .msi
   - Download and run the installer

2. **Installation Settings**:
   - ✅ Add to PATH environment variable
   - ✅ Associate .jar files with Java
   - Install location: Default (`C:\Program Files\Eclipse Adoptium\jdk-11.x.x.x-hotspot\`)

3. **Verify Installation**:
   ```powershell
   # Open PowerShell as Administrator and run:
   java -version
   # Should show: openjdk version "11.x.x"
   ```

### Method 2: Using Chocolatey (Alternative)

```powershell
# Install Chocolatey first (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install OpenJDK 11
choco install openjdk11
```

---

## 🛠️ Step 2: Install Jenkins

### Download and Install

1. **Download Jenkins**:
   - Go to [https://www.jenkins.io/download/](https://www.jenkins.io/download/)
   - Click "Windows" under "LTS Release"
   - Download the `.msi` installer

2. **Run Installer**:
   - Run as Administrator
   - Installation path: Default (`C:\Program Files\Jenkins\`)
   - Service settings: 
     - ✅ Run service as Local System (default)
     - Port: 8080 (default)
     - ✅ Start Jenkins after installation

3. **Initial Setup**:
   - Jenkins will automatically open in browser: `http://localhost:8080`
   - If not, manually navigate to `http://localhost:8080`

### Get Initial Admin Password

```powershell
# Method 1: Using PowerShell
Get-Content "C:\ProgramData\Jenkins\.jenkins\secrets\initialAdminPassword"

# Method 2: Using Command Prompt
type "C:\ProgramData\Jenkins\.jenkins\secrets\initialAdminPassword"

# Method 3: Manual navigation
# Go to: C:\ProgramData\Jenkins\.jenkins\secrets\initialAdminPassword
# Open the file in Notepad and copy the password
```

### Complete Jenkins Setup Wizard

1. **Unlock Jenkins**:
   - Enter the initial admin password
   - Click "Continue"

2. **Customize Jenkins**:
   - Select "Install suggested plugins"
   - Wait for plugins to install (5-10 minutes)

3. **Create First Admin User**:
   ```
   Username: admin (or your preferred username)
   Password: [create a secure password]
   Confirm password: [confirm the password]
   Full name: Your Name
   E-mail address: your-email@example.com
   ```

4. **Instance Configuration**:
   - Jenkins URL: `http://localhost:8080/` (default is fine)
   - Click "Save and Finish"

5. **Start Using Jenkins**:
   - Click "Start using Jenkins"

---

## 📦 Step 3: Install Node.js

1. **Download Node.js**:
   - Go to [https://nodejs.org/](https://nodejs.org/)
   - Download LTS version (18.x.x or 20.x.x)
   - Choose Windows Installer (.msi)

2. **Installation**:
   - Run the installer
   - ✅ Add to PATH (default)
   - ✅ Install npm package manager (default)
   - ✅ Install additional tools for native modules (recommended)

3. **Verify Installation**:
   ```powershell
   node --version
   npm --version
   # Should show version numbers
   ```

---

## 🔧 Step 4: Install Git for Windows

1. **Download Git**:
   - Go to [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - Download will start automatically

2. **Installation Settings** (important choices):
   - Editor: Use Visual Studio Code (or your preferred editor)
   - PATH environment: "Git from the command line and also from 3rd-party software"
   - HTTPS transport: "Use the OpenSSL library"
   - Line ending conversions: "Checkout Windows-style, commit Unix-style"
   - Terminal emulator: "Use Windows' default console window"

3. **Verify Installation**:
   ```powershell
   git --version
   # Should show: git version 2.x.x
   ```

---

## ☁️ Step 5: Install Azure CLI

1. **Download Azure CLI**:
   - Go to [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
   - Download the MSI installer

2. **Install**:
   - Run the installer
   - Follow default settings

3. **Verify Installation**:
   ```powershell
   az --version
   # Should show Azure CLI version and components
   ```

---

## 🔌 Step 6: Install Jenkins Plugins

1. **Access Plugin Manager**:
   - Go to Jenkins Dashboard
   - Click "Manage Jenkins" → "Manage Plugins"

2. **Install Required Plugins**:
   - Go to "Available" tab
   - Search and install these plugins (one by one):

   ```
   ✅ GitHub Plugin
   ✅ Pipeline Plugin (usually pre-installed)
   ✅ NodeJS Plugin
   ✅ Credentials Plugin (usually pre-installed) 
   ✅ Git Plugin (usually pre-installed)
   ✅ Workspace Cleanup Plugin
   ✅ Build Timeout Plugin
   ✅ Timestamper Plugin
   ```

3. **Installation**:
   - Check each plugin
   - Click "Install without restart"
   - After installation, check "Restart Jenkins when installation is complete"

---

## ⚙️ Step 7: Configure Jenkins Tools

### Configure Node.js

1. **Go to Global Tool Configuration**:
   - Manage Jenkins → Global Tool Configuration

2. **Add NodeJS Installation**:
   - Scroll to "NodeJS" section
   - Click "Add NodeJS"
   - Settings:
     ```
     Name: Node18
     Install automatically: ✅
     Version: NodeJS 18.x.x (choose latest 18.x)
     Global npm packages to install: (leave empty)
     ```
   - Click "Save"

### Verify Git Configuration

1. **Check Git Installation**:
   - In Global Tool Configuration
   - Scroll to "Git" section
   - Should show: `C:\Program Files\Git\bin\git.exe`
   - If not detected, click "Add Git" and specify path

---

## 🔐 Step 8: Configure Jenkins Credentials

### Add Azure Service Principal Credentials

1. **Navigate to Credentials**:
   - Manage Jenkins → Manage Credentials
   - Click "System" → "Global credentials (unrestricted)"
   - Click "Add Credentials"

2. **Add Each Credential** (create these one by one):

   **Credential 1 - Azure Client ID**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: [your-azure-client-id-from-service-principal]
   ID: azure-client-id
   Description: Azure Client ID for Jenkins
   ```

   **Credential 2 - Azure Client Secret**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: [your-azure-client-secret-from-service-principal]
   ID: azure-client-secret
   Description: Azure Client Secret for Jenkins
   ```

   **Credential 3 - Azure Tenant ID**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: [your-azure-tenant-id-from-service-principal]
   ID: azure-tenant-id
   Description: Azure Tenant ID for Jenkins
   ```

   **Credential 4 - Azure Subscription ID**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: [your-azure-subscription-id]
   ID: azure-subscription-id
   Description: Azure Subscription ID for Jenkins
   ```

   **Credential 5 - Resource Group**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: rg-assignment3-yourname
   ID: azure-resource-group
   Description: Azure Resource Group Name
   ```

   **Credential 6 - Function App Name**:
   ```
   Kind: Secret text
   Scope: Global
   Secret: func-assignment3-yourname
   ID: azure-function-app-name
   Description: Azure Function App Name
   ```

### Add GitHub Credentials

1. **Create GitHub Personal Access Token** (if not done already):
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token (classic)
   - Scopes: `repo`, `workflow`
   - Copy the token

2. **Add GitHub Credentials to Jenkins**:
   ```
   Kind: Username with password
   Scope: Global
   Username: your-github-username
   Password: your-github-personal-access-token
   ID: github-credentials
   Description: GitHub Personal Access Token
   ```

---

## 🚀 Step 9: Create Jenkins Pipeline

### Create New Pipeline Job

1. **New Item**:
   - Jenkins Dashboard → "New Item"
   - Item name: `Azure-Function-CICD-Pipeline`
   - Select "Pipeline"
   - Click "OK"

2. **Configure Pipeline**:

   **General Section**:
   ```
   Description: CI/CD Pipeline for Azure Functions - Assignment 3
   ✅ GitHub project: https://github.com/yourusername/assignment3-cicd-yourname
   ```

   **Build Triggers**:
   ```
   ✅ GitHub hook trigger for GITScm polling
   ✅ Poll SCM: H/5 * * * * (optional - polls every 5 minutes)
   ```

   **Pipeline Section**:
   ```
   Definition: Pipeline script from SCM
   SCM: Git
   Repository URL: https://github.com/yourusername/assignment3-cicd-yourname.git
   Credentials: [select your GitHub credentials]
   Branches to build: */main
   Script Path: Jenkinsfile
   ```

3. **Save Configuration**:
   - Click "Save"

---

## 🧪 Step 10: Test Jenkins Setup

### Test Jenkins Service

```powershell
# Check if Jenkins service is running
Get-Service -Name "Jenkins"

# Start Jenkins service if stopped
Start-Service -Name "Jenkins"

# Stop Jenkins service if needed
Stop-Service -Name "Jenkins"
```

### Test Azure CLI Integration

1. **Open PowerShell as Administrator**
2. **Test Azure CLI**:
   ```powershell
   # Test Azure CLI
   az --version
   
   # Test login (use your service principal)
   az login --service-principal `
     --username "your-client-id" `
     --password "your-client-secret" `
     --tenant "your-tenant-id"
   
   # Test access to your resources
   az group list --query "[?name=='rg-assignment3-yourname']"
   
   # Logout
   az logout
   ```

### Test Node.js Integration

```powershell
# Navigate to your project directory
cd "C:\path\to\your\project"

# Test npm
npm --version

# Install dependencies (if package.json exists)
npm install

# Run tests (if configured)
npm test
```

---

## 🔍 Step 11: Troubleshooting Common Windows Issues

### Issue 1: "Java not found" Error

**Solution**:
```powershell
# Check Java installation
java -version

# If not found, add to PATH manually:
# System Properties → Environment Variables → System Variables → PATH
# Add: C:\Program Files\Eclipse Adoptium\jdk-11.x.x.x-hotspot\bin
```

### Issue 2: Jenkins Service Won't Start

**Solutions**:
```powershell
# Method 1: Restart service
Restart-Service -Name "Jenkins"

# Method 2: Check Windows Services
# Press Win+R, type "services.msc", find Jenkins, right-click → Restart

# Method 3: Check port conflicts
netstat -ano | findstr :8080
# If port 8080 is used, change Jenkins port in:
# C:\Program Files\Jenkins\jenkins.xml
```

### Issue 3: PowerShell Execution Policy Error

**Solution**:
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue 4: Azure CLI Commands Fail in Jenkins

**Solution**: Ensure Jenkins service has proper permissions
```powershell
# Run Jenkins as Administrator (not recommended for production)
# Or configure proper Windows service permissions
```

### Issue 5: Git Commands Fail

**Solution**: Add Git to System PATH
```
System Properties → Environment Variables → System Variables → PATH
Add: C:\Program Files\Git\bin
```

---

## 📝 Step 12: Final Verification Checklist

### ✅ Services Running:
```powershell
# Check all required services
Get-Service -Name "Jenkins"
# Should show: Status = Running

# Test URLs
# Jenkins: http://localhost:8080
# Should load Jenkins dashboard
```

### ✅ Command Line Tools:
```powershell
java -version       # Should show Java 11+ 
node --version      # Should show Node.js 18+
npm --version       # Should show npm version
git --version       # Should show Git version
az --version        # Should show Azure CLI version
```

### ✅ Jenkins Configuration:
- [ ] Jenkins accessible at http://localhost:8080
- [ ] Admin user created
- [ ] Required plugins installed
- [ ] Node.js tool configured
- [ ] All Azure credentials added
- [ ] GitHub credentials added
- [ ] Pipeline job created

---

## 🎯 Next Steps

1. **Clone/Create your GitHub repository**
2. **Push the project files to GitHub**
3. **Run your first Jenkins build**
4. **Verify Azure deployment**

### Quick Test Build

1. **Go to your pipeline job**
2. **Click "Build Now"**
3. **Monitor the console output**
4. **Verify all stages complete successfully**

---

## 📞 Windows-Specific Support Commands

```powershell
# Jenkins logs location
Get-Content "C:\ProgramData\Jenkins\.jenkins\logs\jenkins.log" -Tail 50

# Jenkins configuration location
explorer "C:\ProgramData\Jenkins\.jenkins"

# Restart Jenkins service
Restart-Service -Name "Jenkins"

# Check Windows Event Viewer for Jenkins errors
eventvwr.msc
# Navigate to: Windows Logs → Application → Filter by Source: Jenkins
```

**Your Windows Jenkins setup is now complete! 🎉**

**Next**: Proceed with the main SETUP_GUIDE.md for GitHub integration and pipeline testing.