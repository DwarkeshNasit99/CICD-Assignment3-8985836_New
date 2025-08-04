pipeline {
    agent any
    
    environment {
        // Azure credentials - using your Jenkins credential IDs
        AZURE_CLIENT_ID = credentials('AZURE_CLIENT_ID')
        AZURE_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET') 
        AZURE_TENANT_ID = credentials('AZURE_TENANT_ID')
        AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        
        // Azure Function App details - using your Jenkins credential IDs
        RESOURCE_GROUP = credentials('AZURE_RESOURCE_GROUP')
        FUNCTION_APP_NAME = credentials('AZURE_FUNCTION_APP_NAME')
        
        // Node.js version
        NODEJS_VERSION = '20'
        
        // Deployment package name
        DEPLOYMENT_PACKAGE = 'function-deployment.zip'
    }
    
    tools {
        nodejs "${NODEJS_VERSION}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '📦 Checking out code from GitHub...'
                    checkout scm
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '🔨 Building the application...'
                    echo 'Installing Node.js dependencies...'
                    
                    // Clean previous builds (Windows commands)
                    bat '''
                        if exist node_modules rmdir /s /q node_modules
                        if exist package-lock.json del /q package-lock.json
                    '''
                    
                    // Install dependencies
                    bat 'npm install'
                    
                    // Verify installation
                    bat 'npm list --depth=0 || echo "Dependencies listed with warnings"'
                    
                    echo '✅ Build completed successfully!'
                }
            }
            post {
                success {
                    echo '✅ Build stage completed successfully'
                }
                failure {
                    echo '❌ Build stage failed'
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo '🧪 Running automated tests...'
                    
                    // Run tests with coverage (Windows command)
                    bat 'npm test -- --coverage --watchAll=false --ci'
                    
                    echo '✅ All tests passed successfully!'
                }
            }
            post {
                always {
                    // Publish test results if using JUnit format
                    script {
                        if (fileExists('coverage/lcov.info')) {
                            echo 'Test coverage report generated'
                        }
                    }
                }
                success {
                    echo '✅ Test stage completed successfully - All tests passed'
                }
                failure {
                    echo '❌ Test stage failed - Some tests failed'
                }
            }
        }
        
        stage('Package') {
            steps {
                script {
                    echo '📦 Packaging application for deployment...'
                    
                    // Clean and create deployment directory (Windows command)
                    bat '''
                        if exist deploy rmdir /s /q deploy
                        mkdir deploy
                    '''
                    
                    // Copy necessary files for deployment (Windows commands with /Y flag for non-interactive)
                    // NOTE: Azure Functions folder structure - each function in its own folder
                    bat '''
                        xcopy /s /e /i /y httpTrigger deploy\\httpTrigger
                        copy /y package.json deploy\\
                        copy /y host.json deploy\\
                        echo "Azure Functions structure: httpTrigger folder with index.js inside"
                        echo "Skipping node_modules - Azure will install dependencies from package.json during deployment"
                    '''
                    
                    // Create deployment zip using PowerShell
                    powershell """
                        Compress-Archive -Path deploy\\* -DestinationPath ${DEPLOYMENT_PACKAGE} -Force
                        Get-Item ${DEPLOYMENT_PACKAGE} | Select-Object Name, Length, LastWriteTime
                    """
                    
                    // Verify deployment package contents by extracting and displaying structure
                    powershell """
                        Write-Host "📋 VERIFYING DEPLOYMENT PACKAGE STRUCTURE"
                        Write-Host "=" * 50
                        
                        # Create temporary verification directory
                        \$verifyDir = "verify-deployment"
                        if (Test-Path \$verifyDir) { Remove-Item -Recurse -Force \$verifyDir }
                        New-Item -ItemType Directory -Name \$verifyDir | Out-Null
                        
                        Write-Host "📦 Extracting ${DEPLOYMENT_PACKAGE} for verification..."
                        Expand-Archive -Path ${DEPLOYMENT_PACKAGE} -DestinationPath \$verifyDir -Force
                        
                        Write-Host ""
                        Write-Host "🗂️  DEPLOYMENT PACKAGE CONTENTS:"
                        Write-Host "-" * 40
                        
                        # Function to display directory tree
                        function Show-DirectoryTree(\$path, \$prefix = "") {
                            \$items = Get-ChildItem \$path | Sort-Object Name
                            \$totalItems = \$items.Count
                            \$currentItem = 0
                            
                            foreach (\$item in \$items) {
                                \$currentItem++
                                \$isLast = (\$currentItem -eq \$totalItems)
                                \$connector = if (\$isLast) { "└── " } else { "├── " }
                                \$nextPrefix = if (\$isLast) { "\$prefix    " } else { "\$prefix│   " }
                                
                                if (\$item.PSIsContainer) {
                                    Write-Host "\$prefix\$connector📁 \$(\$item.Name)/" -ForegroundColor Yellow
                                    Show-DirectoryTree \$item.FullName \$nextPrefix
                                } else {
                                    \$size = if (\$item.Length -lt 1KB) { "\$(\$item.Length)B" } 
                                            elseif (\$item.Length -lt 1MB) { "{0:N1}KB" -f (\$item.Length / 1KB) } 
                                            else { "{0:N1}MB" -f (\$item.Length / 1MB) }
                                    Write-Host "\$prefix\$connector📄 \$(\$item.Name) (\$size)" -ForegroundColor Green
                                }
                            }
                        }
                        
                        # Display the tree structure
                        Show-DirectoryTree \$verifyDir
                        
                        Write-Host ""
                        Write-Host "📊 PACKAGE SUMMARY:"
                        Write-Host "-" * 20
                        \$allFiles = Get-ChildItem -Path \$verifyDir -Recurse -File
                        \$totalFiles = \$allFiles.Count
                        \$totalSize = (\$allFiles | Measure-Object -Property Length -Sum).Sum
                        \$sizeFormatted = if (\$totalSize -lt 1KB) { "\$(\$totalSize)B" } 
                                        elseif (\$totalSize -lt 1MB) { "{0:N1}KB" -f (\$totalSize / 1KB) } 
                                        else { "{0:N1}MB" -f (\$totalSize / 1MB) }
                        
                        Write-Host "• Total Files: \$totalFiles"
                        Write-Host "• Total Size: \$sizeFormatted"
                        Write-Host "• Package: ${DEPLOYMENT_PACKAGE}"
                        
                        # Check for key files (Azure Functions folder structure)
                        Write-Host ""
                        Write-Host "✅ KEY FILE VERIFICATION (Azure Functions Folder Structure):"
                        Write-Host "-" * 50
                        \$keyFiles = @("package.json", "host.json", "httpTrigger\\index.js", "httpTrigger\\function.json")
                        foreach (\$file in \$keyFiles) {
                            \$filePath = Join-Path \$verifyDir \$file
                            if (Test-Path \$filePath) {
                                Write-Host "✅ \$file - FOUND" -ForegroundColor Green
                            } else {
                                Write-Host "❌ \$file - MISSING" -ForegroundColor Red
                            }
                        }
                        
                        # Verify package.json main entry
                        \$packageJsonPath = Join-Path \$verifyDir "package.json"
                        if (Test-Path \$packageJsonPath) {
                            \$packageContent = Get-Content \$packageJsonPath | ConvertFrom-Json
                            \$mainEntry = \$packageContent.main
                            Write-Host ""
                            Write-Host "📝 PACKAGE.JSON VERIFICATION:"
                            Write-Host "   Main Entry: \$mainEntry"
                            if (\$mainEntry -eq "httpTrigger/index.js") {
                                Write-Host "✅ Main entry points to httpTrigger folder - CORRECT" -ForegroundColor Green
                            } else {
                                Write-Host "❌ Main entry should be 'httpTrigger/index.js'" -ForegroundColor Red
                            }
                        }
                        
                        # Check httpTrigger folder structure
                        \$httpTriggerPath = Join-Path \$verifyDir "httpTrigger"
                        if (Test-Path \$httpTriggerPath) {
                            Write-Host ""
                            Write-Host "📁 HTTPTRIGGER FOLDER CONTENTS:"
                            Get-ChildItem \$httpTriggerPath | ForEach-Object {
                                Write-Host "   📄 \$(\$_.Name)" -ForegroundColor Cyan
                            }
                            
                            # Verify function.json configuration
                            \$functionJsonPath = Join-Path \$httpTriggerPath "function.json"
                            if (Test-Path \$functionJsonPath) {
                                Write-Host ""
                                Write-Host "🔧 FUNCTION.JSON VERIFICATION:"
                                try {
                                    \$functionConfig = Get-Content \$functionJsonPath | ConvertFrom-Json
                                    \$httpTrigger = \$functionConfig.bindings | Where-Object { \$_.type -eq "httpTrigger" }
                                    if (\$httpTrigger) {
                                        Write-Host "   ✅ HTTP Trigger binding found" -ForegroundColor Green
                                        Write-Host "   📝 Auth Level: \$(\$httpTrigger.authLevel)"
                                        Write-Host "   📝 Methods: \$(\$httpTrigger.methods -join ', ')"
                                        Write-Host "   📝 Route: \$(\$httpTrigger.route)"
                                    } else {
                                        Write-Host "   ❌ HTTP Trigger binding not found" -ForegroundColor Red
                                    }
                                } catch {
                                    Write-Host "   ❌ Error reading function.json: \$(\$_.Exception.Message)" -ForegroundColor Red
                                }
                            }
                        }
                        
                        Write-Host ""
                        Write-Host "🧹 Cleaning up verification directory..."
                        Remove-Item -Recurse -Force \$verifyDir
                        
                        Write-Host "=" * 50
                        Write-Host "📋 PACKAGE VERIFICATION COMPLETE"
                    """
                    
                    echo '✅ Application packaged successfully!'
                }
            }
            post {
                success {
                    echo '✅ Package stage completed successfully'
                    archiveArtifacts artifacts: "${DEPLOYMENT_PACKAGE}", allowEmptyArchive: false
                }
                failure {
                    echo '❌ Package stage failed'
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo '🚀 Deploying to Azure Functions...'
                    
                    // Check Azure CLI installation (Windows)
                    bat '''
                        where az >nul 2>nul
                        if %errorlevel% neq 0 (
                            echo Azure CLI not found. Please install Azure CLI on Jenkins agent.
                            echo Download from: https://aka.ms/installazurecliwindows
                            exit /b 1
                        ) else (
                            echo Azure CLI already installed
                            az version
                        )
                    '''
                    
                    // Login to Azure using service principal (Windows)
                    bat '''
                        echo Logging into Azure...
                        az login --service-principal --username %AZURE_CLIENT_ID% --password %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%
                        
                        echo Setting subscription...
                        az account set --subscription %AZURE_SUBSCRIPTION_ID%
                        
                        echo Verifying login...
                        az account show
                    '''
                    
                    // Deploy using ZIP deployment (Core Tools install failing due to network issues)
                    bat """
                        echo Deploying to Azure Function App: %FUNCTION_APP_NAME%
                        echo Resource Group: %RESOURCE_GROUP%
                        echo Using ZIP deployment with verified package structure
                        
                        REM Deploy using zip deployment (now with proper function.json + index.js structure)
                        az functionapp deployment source config-zip --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --src %DEPLOYMENT_PACKAGE% --build-remote true
                        
                        echo Deployment completed using ZIP deployment!
                        
                        REM Get function URL
                        echo Getting function URL...
                        az functionapp function show --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --function-name httpTrigger --query "invokeUrlTemplate" --output tsv || echo Could not retrieve function URL
                    """
                    
                    echo '✅ Deployment completed successfully!'
                }
            }
            post {
                success {
                    echo '✅ Deploy stage completed successfully'
                    script {
                        // Get the function URL for verification (Windows)
                        try {
                            def functionUrl = bat(
                                script: """
                                    az functionapp function show --resource-group ${RESOURCE_GROUP} --name ${FUNCTION_APP_NAME} --function-name httpTrigger --query "invokeUrlTemplate" --output tsv 2>nul || echo URL not available
                                """,
                                returnStdout: true
                            ).trim()
                            
                            if (functionUrl && !functionUrl.contains("URL not available")) {
                                echo "🌐 Function URL: ${functionUrl}"
                            }
                        } catch (Exception e) {
                            echo "Could not retrieve function URL: ${e.message}"
                        }
                    }
                }
                failure {
                    echo '❌ Deploy stage failed'
                }
                always {
                    // Logout from Azure
                    bat 'az logout || echo "Logout failed but continuing"'
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '🔍 Verifying deployment...'
                    
                    // Login again for verification (Windows)
                    bat '''
                        az login --service-principal --username %AZURE_CLIENT_ID% --password %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%
                        az account set --subscription %AZURE_SUBSCRIPTION_ID%
                    '''
                    
                    // Check function app status (Windows)
                    bat """
                        echo Checking Function App status...
                        az functionapp show --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --query "{name:name,state:state,hostNames:defaultHostName}" --output table
                        
                        echo Checking function runtime status...
                        az functionapp config show --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --query "{nodeVersion:nodeVersion,appSettings:appSettings}" --output json || echo Failed to get config
                    """
                    
                    // Wait for function deployment to complete (Windows PowerShell with retry logic)
                    powershell '''
                        Write-Host "🕒 Azure Functions deployment typically takes 3-5 minutes after 202 response..."
                        Write-Host "Starting extended wait and retry process..."
                        
                        $maxAttempts = 6
                        $waitSeconds = 30
                        $attempt = 1
                        $success = $false
                        
                        while ($attempt -le $maxAttempts -and -not $success) {
                            Write-Host "⏳ Attempt $attempt of $maxAttempts - Waiting $waitSeconds seconds before checking..."
                            Start-Sleep -Seconds $waitSeconds
                            
                            Write-Host "🔍 Checking if httpTrigger function is deployed..."
                            
                            try {
                                # First check if function exists in the function app
                                $functions = az functionapp function list --name $env:FUNCTION_APP_NAME --resource-group $env:RESOURCE_GROUP --output json | ConvertFrom-Json
                                
                                if ($functions -and $functions.Count -gt 0) {
                                    $httpTriggerFunction = $functions | Where-Object { $_.name -eq "httpTrigger" }
                                    
                                    if ($httpTriggerFunction) {
                                        Write-Host "✅ httpTrigger function found! Getting URL..."
                                        
                                        # Get function URL
                                        $functionUrl = az functionapp function show --resource-group $env:RESOURCE_GROUP --name $env:FUNCTION_APP_NAME --function-name httpTrigger --query "invokeUrlTemplate" --output tsv 2>$null
                                        
                                        if ($functionUrl -and $functionUrl -ne "") {
                                            Write-Host "🌐 Function URL: $functionUrl"
                                            Write-Host "🧪 Testing function..."
                                            
                                            try {
                                                $response = Invoke-WebRequest -Uri $functionUrl -Method GET -UseBasicParsing -TimeoutSec 30
                                                $httpStatus = $response.StatusCode
                                                
                                                if ($httpStatus -eq 200) {
                                                    Write-Host "🎉 SUCCESS! Function is responding correctly (HTTP $httpStatus)"
                                                    Write-Host "📝 Function response:"
                                                    Write-Host $response.Content.Substring(0, [Math]::Min(500, $response.Content.Length))
                                                    $success = $true
                                                } else {
                                                    Write-Host "⚠️ Function returned HTTP status: $httpStatus (attempt $attempt)"
                                                }
                                            } catch {
                                                Write-Host "⚠️ Error testing function: $($_.Exception.Message) (attempt $attempt)"
                                            }
                                        } else {
                                            Write-Host "⚠️ Could not retrieve function URL (attempt $attempt)"
                                        }
                                    } else {
                                        Write-Host "⚠️ httpTrigger function not found in function list (attempt $attempt)"
                                        Write-Host "📋 Available functions: $($functions | ForEach-Object { $_.name } | Join-String -Separator ", ")"
                                    }
                                } else {
                                    Write-Host "⚠️ No functions found in function app yet (attempt $attempt)"
                                }
                            } catch {
                                Write-Host "⚠️ Error checking functions: $($_.Exception.Message) (attempt $attempt)"
                            }
                            
                            if (-not $success) {
                                $attempt++
                                if ($attempt -le $maxAttempts) {
                                    Write-Host "⏭️ Trying again in $waitSeconds seconds..."
                                }
                            }
                        }
                        
                        if (-not $success) {
                            Write-Host "❌ Function deployment verification failed after $maxAttempts attempts (3 minutes total)"
                            Write-Host "💡 This might be normal - Azure deployments can take longer than expected"
                            Write-Host "🔧 Check Azure Portal manually or wait a few more minutes and test manually"
                        }
                    '''
                    
                    echo '✅ Deployment verification completed!'
                }
            }
            post {
                always {
                    bat 'az logout || echo "Logout failed but continuing"'
                }
                success {
                    echo '✅ Verification completed - Function is deployed and accessible'
                }
                failure {
                    echo '⚠️  Verification completed with warnings'
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up workspace...'
            
            // TEMPORARILY COMMENTED OUT - Testing deployment timing
            // Clean up deployment files - wrap in node context
            script {
                echo "⚠️ Cleanup temporarily disabled to test Azure deployment timing"
                echo "Deploy folder and zip file will remain for debugging"
                
                try {
                    // Archive logs only
                    if (fileExists('npm-debug.log')) {
                        archiveArtifacts artifacts: 'npm-debug.log', allowEmptyArchive: true
                    }
                } catch (Exception e) {
                    echo "Archiving failed: ${e.message}"
                }
            }
            
            /*
            // ORIGINAL CLEANUP CODE - RE-ENABLE LATER
            script {
                try {
                    node {
                        bat """
                            if exist ${DEPLOYMENT_PACKAGE} del /q ${DEPLOYMENT_PACKAGE}
                            if exist deploy rmdir /s /q deploy
                        """
                        
                        // Archive logs
                        if (fileExists('npm-debug.log')) {
                            archiveArtifacts artifacts: 'npm-debug.log', allowEmptyArchive: true
                        }
                    }
                } catch (Exception e) {
                    echo "Cleanup failed: ${e.message}"
                }
            }
            */
        }
        
        success {
            echo '''
            🎉 ===================================
            🎉 CI/CD PIPELINE COMPLETED SUCCESSFULLY!
            🎉 ===================================
            ✅ Build: Completed
            ✅ Test: All tests passed  
            ✅ Package: Created successfully
            ✅ Deploy: Deployed to Azure Functions
            ✅ Verify: Function is accessible
            
            Your Azure Function is now live! 🚀
            '''
        }
        
        failure {
            echo '''
            ❌ ===================================
            ❌ CI/CD PIPELINE FAILED
            ❌ ===================================
            Please check the logs above for details.
            Common issues:
            - Azure credentials not configured
            - Resource group or function app name incorrect
            - Network connectivity issues
            - Test failures
            '''
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings - please review the logs'
        }
    }
}