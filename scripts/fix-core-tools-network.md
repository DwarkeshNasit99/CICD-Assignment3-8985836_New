# Fixing Azure Functions Core Tools Network Issues

## Root Cause Analysis
The error `ECONNRESET` when installing Azure Functions Core Tools indicates:
1. **Network connectivity issues** to Azure CDN
2. **Corporate firewall/proxy** blocking downloads
3. **Windows permissions** issues
4. **npm registry configuration** problems

## Solution 1: Configure npm for Corporate Environment

```bash
# Set npm registry and proxy (if behind corporate firewall)
npm config set registry https://registry.npmjs.org/
npm config set strict-ssl false
npm config set proxy http://your-proxy:port
npm config set https-proxy http://your-proxy:port

# Try installing with different flags
npm install -g azure-functions-core-tools@4 --unsafe-perm true --force
```

## Solution 2: Manual Download and Install

```powershell
# Download directly from GitHub releases (more reliable)
$version = "4.0.5907"
$url = "https://github.com/Azure/azure-functions-core-tools/releases/download/$version/Azure.Functions.Cli.win-x64.$version.zip"
$destination = "C:\azure-functions-core-tools"

# Download
Invoke-WebRequest -Uri $url -OutFile "func-tools.zip" -UseBasicParsing

# Extract
Expand-Archive -Path "func-tools.zip" -DestinationPath $destination -Force

# Add to PATH
$env:PATH += ";$destination"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, "Machine")
```

## Solution 3: Use Chocolatey Package Manager

```powershell
# Install Chocolatey first (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Azure Functions Core Tools via Chocolatey
choco install azure-functions-core-tools -y
```

## Solution 4: Jenkins Agent Configuration

### Windows Jenkins Agent Setup:
1. **Run Jenkins as Administrator**
2. **Configure npm permissions**:
   ```cmd
   npm config set cache C:\npm-cache --global
   npm config set prefix C:\npm-global --global
   ```
3. **Set environment variables**:
   ```cmd
   setx PATH "%PATH%;C:\npm-global" /M
   ```

## Solution 5: Alternative CDN Sources

```powershell
# Try different download sources
$sources = @(
    "https://github.com/Azure/azure-functions-core-tools/releases/download/4.0.5907/Azure.Functions.Cli.win-x64.4.0.5907.zip",
    "https://functionscdn.azureedge.net/public/4.0.5907/Azure.Functions.Cli.win-x64.4.0.5907.zip"
)

foreach ($source in $sources) {
    try {
        Write-Host "Trying source: $source"
        Invoke-WebRequest -Uri $source -OutFile "func-tools.zip" -TimeoutSec 30
        Write-Host "Success with source: $source"
        break
    } catch {
        Write-Host "Failed with source: $source"
        continue
    }
}
```

## Solution 6: Docker-based Deployment

```dockerfile
# Use Azure Functions Docker image for deployment
FROM mcr.microsoft.com/azure-functions/node:4-node18

COPY . /app
WORKDIR /app

RUN npm install
RUN func azure functionapp publish $FUNCTION_APP_NAME --build-remote
```

## Jenkins Pipeline Integration

```groovy
// Add this to your Jenkinsfile Deploy stage
script {
    // Try to install Core Tools with multiple methods
    def coreToolsInstalled = false
    
    // Method 1: Check if already installed
    try {
        bat 'func --version'
        coreToolsInstalled = true
        echo '✅ Core Tools already installed'
    } catch (Exception e) {
        echo 'Core Tools not found, attempting installation...'
    }
    
    // Method 2: Try npm install with different configurations
    if (!coreToolsInstalled) {
        try {
            bat '''
                npm config set registry https://registry.npmjs.org/
                npm config set strict-ssl false
                npm install -g azure-functions-core-tools@4 --unsafe-perm true --force --timeout=300000
            '''
            coreToolsInstalled = true
            echo '✅ Core Tools installed via npm'
        } catch (Exception e) {
            echo 'npm installation failed, trying alternatives...'
        }
    }
    
    // Method 3: Manual download
    if (!coreToolsInstalled) {
        try {
            powershell '''
                $url = "https://github.com/Azure/azure-functions-core-tools/releases/download/4.0.5907/Azure.Functions.Cli.win-x64.4.0.5907.zip"
                $dest = "C:\\func-tools"
                New-Item -ItemType Directory -Path $dest -Force
                Invoke-WebRequest -Uri $url -OutFile "$dest\\func.zip" -UseBasicParsing
                Expand-Archive -Path "$dest\\func.zip" -DestinationPath $dest -Force
                $env:PATH += ";$dest"
            '''
            coreToolsInstalled = true
            echo '✅ Core Tools installed via manual download'
        } catch (Exception e) {
            echo 'Manual installation failed'
        }
    }
    
    // Use Core Tools if available, otherwise fallback to ZIP
    if (coreToolsInstalled) {
        bat '''
            cd deploy
            func azure functionapp publish %FUNCTION_APP_NAME% --build-remote
        '''
    } else {
        echo 'Using ZIP deployment fallback...'
        bat '''
            az functionapp deployment source config-zip --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --src %DEPLOYMENT_PACKAGE% --build-remote true
        '''
    }
}
```

## Network Troubleshooting Commands

```bash
# Test connectivity to Azure CDN
curl -I https://cdn.functions.azure.com/public/4.0.5907/Azure.Functions.Cli.win-x64.4.0.5907.zip

# Check npm configuration
npm config list
npm config get registry
npm config get proxy

# Test with verbose logging
npm install -g azure-functions-core-tools@4 --verbose --unsafe-perm true
```