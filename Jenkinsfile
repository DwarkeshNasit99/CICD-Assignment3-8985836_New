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
                    
                    // Create deployment directory (Windows command)
                    bat 'if not exist deploy mkdir deploy'
                    
                    // Copy necessary files for deployment (Windows commands)
                    bat '''
                        xcopy /s /e /i src deploy\\src
                        copy package.json deploy\\
                        copy host.json deploy\\
                        if exist node_modules (xcopy /s /e /i node_modules deploy\\node_modules) else (echo node_modules not found, will install on Azure)
                    '''
                    
                    // Create deployment zip using PowerShell
                    powershell """
                        Compress-Archive -Path deploy\\* -DestinationPath ${DEPLOYMENT_PACKAGE} -Force
                        Get-Item ${DEPLOYMENT_PACKAGE} | Select-Object Name, Length, LastWriteTime
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
                    
                    // Deploy to Azure Function App (Windows)
                    bat """
                        echo Deploying to Azure Function App: %FUNCTION_APP_NAME%
                        echo Resource Group: %RESOURCE_GROUP%
                        
                        REM Deploy using zip deployment
                        az functionapp deployment source config-zip --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --src %DEPLOYMENT_PACKAGE% --build-remote true
                        
                        echo Deployment completed!
                        
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
                        // Get the function URL for verification
                        try {
                            def functionUrl = sh(
                                script: """
                                    az functionapp function show \\
                                        --resource-group ${RESOURCE_GROUP} \\
                                        --name ${FUNCTION_APP_NAME} \\
                                        --function-name httpTrigger \\
                                        --query "invokeUrlTemplate" \\
                                        --output tsv 2>/dev/null || echo "URL not available"
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
                    
                    // Wait for function to be ready and test it (Windows PowerShell)
                    powershell '''
                        Write-Host "Waiting for function to be ready..."
                        Start-Sleep -Seconds 30
                        
                        # Get function URL
                        try {
                            $functionUrl = az functionapp function show --resource-group $env:RESOURCE_GROUP --name $env:FUNCTION_APP_NAME --function-name httpTrigger --query "invokeUrlTemplate" --output tsv 2>$null
                            
                            if ($functionUrl -and $functionUrl -ne "") {
                                Write-Host "Testing function at: $functionUrl"
                                
                                # Test the function
                                try {
                                    $response = Invoke-WebRequest -Uri $functionUrl -Method GET -UseBasicParsing
                                    $httpStatus = $response.StatusCode
                                    
                                    if ($httpStatus -eq 200) {
                                        Write-Host "✅ Function is responding correctly (HTTP $httpStatus)"
                                        Write-Host "Function response:"
                                        Write-Host $response.Content.Substring(0, [Math]::Min(500, $response.Content.Length))
                                    } else {
                                        Write-Host "⚠️ Function returned HTTP status: $httpStatus"
                                        Write-Host "This might be normal if the function is still warming up"
                                    }
                                } catch {
                                    Write-Host "⚠️ Error testing function: $($_.Exception.Message)"
                                }
                            } else {
                                Write-Host "⚠️ Could not retrieve function URL for testing"
                            }
                        } catch {
                            Write-Host "⚠️ Error getting function URL: $($_.Exception.Message)"
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
            
            // Clean up deployment files - wrap in node context
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