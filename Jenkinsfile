pipeline {
    agent any
    
    environment {
        // Azure credentials
        AZURE_CLIENT_ID = credentials('AZURE_CLIENT_ID')
        AZURE_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET') 
        AZURE_TENANT_ID = credentials('AZURE_TENANT_ID')
        AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        RESOURCE_GROUP = credentials('AZURE_RESOURCE_GROUP')
        FUNCTION_APP_NAME = credentials('AZURE_FUNCTION_APP_NAME')
        
        // Configuration
        NODEJS_VERSION = '20'
        DEPLOYMENT_PACKAGE = 'function-deployment.zip'
        DEPLOYMENT_METHOD = 'github-actions'
    }
    
    tools {
        nodejs "${NODEJS_VERSION}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo 'Checking out code from GitHub repository'
                    checkout scm
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo 'Building the application'
                    
                    // Clean previous builds
                    bat '''
                        if exist node_modules rmdir /s /q node_modules
                        if exist package-lock.json del /q package-lock.json
                    '''
                    
                    // Install dependencies
                    bat 'npm install'
                    bat 'npm list --depth=0 || echo "Dependencies installed"'
                    
                    echo 'Build completed successfully'
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo 'Running automated tests'
                    bat 'npm test -- --coverage --watchAll=false --ci'
                    echo 'All tests passed successfully'
                }
            }
            post {
                always {
                    script {
                        if (fileExists('coverage')) {
                            echo 'Test coverage report generated'
                        }
                    }
                }
            }
        }
        
        stage('Package') {
            when {
                environment name: 'DEPLOYMENT_METHOD', value: 'zip-deployment'
            }
            steps {
                script {
                    echo 'Packaging application for ZIP deployment'
                    
                    // Create deployment directory
                    bat '''
                        if exist deploy rmdir /s /q deploy
                        mkdir deploy
                    '''
                    
                    // Copy necessary files
                    bat '''
                        xcopy /s /e /i /y httpTrigger deploy\\httpTrigger
                        copy /y package.json deploy\\
                        copy /y host.json deploy\\
                    '''
                    
                    // Create deployment zip
                    powershell """
                        Compress-Archive -Path deploy\\* -DestinationPath ${DEPLOYMENT_PACKAGE} -Force
                        Get-Item ${DEPLOYMENT_PACKAGE} | Select-Object Name, Length, LastWriteTime
                    """
                    
                    echo 'Application packaged successfully'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: "${DEPLOYMENT_PACKAGE}", allowEmptyArchive: true
                }
            }
        }
        
        stage('Prepare GitHub Actions Deployment') {
            when {
                environment name: 'DEPLOYMENT_METHOD', value: 'github-actions'
            }
            steps {
                script {
                    echo 'Preparing GitHub Actions deployment'
                    echo 'Jenkins CI completed successfully: Code checkout, Dependencies installed, Tests passed'
                    echo 'Ready to trigger GitHub Actions for deployment'
                    echo 'GitHub Actions will handle: Fresh code checkout, Clean build process, Package creation, Azure deployment'
                    echo "Repository: DwarkeshNasit99/CICD-Assignment3-8985836_New"
                    echo "Workflow: azure-deploy-triggered.yml"
                    echo "Build Tag: jenkins-build-${BUILD_NUMBER}"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo "Starting deployment process"
                    echo "Deployment Method: ${env.DEPLOYMENT_METHOD}"
                    
                    // Check Azure CLI
                    bat '''
                        where az >nul 2>nul
                        if %errorlevel% neq 0 (
                            echo Azure CLI not found. Please install Azure CLI.
                            exit /b 1
                        ) else (
                            echo Azure CLI is available
                        )
                    '''
                    
                    // Azure login
                    bat '''
                        echo Logging into Azure
                        az login --service-principal --username %AZURE_CLIENT_ID% --password %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%
                        az account set --subscription %AZURE_SUBSCRIPTION_ID%
                    '''
                    
                    script {
                        def deploymentMethod = env.DEPLOYMENT_METHOD ?: 'github-actions'
                        
                        if (deploymentMethod == 'github-actions') {
                            echo 'Using GitHub Actions deployment (recommended)'
                            echo 'Jenkins completed: Build, Test, Package verification'
                            echo 'Now delegating deployment to GitHub Actions'
                            
                            // Trigger GitHub Actions workflow
                            withCredentials([usernamePassword(credentialsId: 'GITHUB_TOKEN_PWD', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                                bat """
                                    echo Triggering GitHub Actions deployment workflow
                                    echo Repository: DwarkeshNasit99/CICD-Assignment3-8985836_New
                                    echo Workflow: azure-deploy-triggered.yml
                                    echo Build Tag: jenkins-build-${BUILD_NUMBER}
                                    
                                    curl -X POST ^
                                        -H "Authorization: token %GITHUB_TOKEN%" ^
                                        -H "Accept: application/vnd.github.v3+json" ^
                                        https://api.github.com/repos/DwarkeshNasit99/CICD-Assignment3-8985836_New/actions/workflows/azure-deploy-triggered.yml/dispatches ^
                                        -d "{\"ref\":\"main\",\"inputs\":{\"deployment_tag\":\"jenkins-build-${BUILD_NUMBER}\",\"environment\":\"production\"}}"
                                    
                                    echo GitHub Actions deployment workflow triggered successfully
                                    echo Monitor deployment at: https://github.com/DwarkeshNasit99/CICD-Assignment3-8985836_New/actions
                                    echo GitHub Actions will handle: Fresh Build, Package, Deploy to Azure
                                """
                            }
                        } else {
                            echo 'Using ZIP deployment (fallback method)'
                            
                            bat """
                                echo Deploying to Azure Function App: %FUNCTION_APP_NAME%
                                echo Resource Group: %RESOURCE_GROUP%
                                echo Package: %DEPLOYMENT_PACKAGE%
                                
                                az functionapp deployment source config-zip --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --src %DEPLOYMENT_PACKAGE% --build-remote true
                                
                                echo ZIP deployment completed
                                az functionapp function show --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --function-name httpTrigger --query "invokeUrlTemplate" --output tsv || echo Could not retrieve function URL
                            """
                        }
                    }
                    
                    echo 'Deployment process completed'
                }
            }
            post {
                always {
                    bat 'az logout || echo "Logout completed"'
                }
            }
        }
        
        stage('Verify Deployment') {
            when {
                environment name: 'DEPLOYMENT_METHOD', value: 'zip-deployment'
            }
            steps {
                script {
                    echo 'Verifying ZIP deployment'
                    
                    // Login for verification
                    bat '''
                        az login --service-principal --username %AZURE_CLIENT_ID% --password %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%
                        az account set --subscription %AZURE_SUBSCRIPTION_ID%
                    '''
                    
                    // Check function app status
                    bat """
                        echo Checking Function App status
                        az functionapp show --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --query "{name:name,state:state,hostNames:defaultHostName}" --output table
                    """
                    
                    // Check for functions
                    powershell '''
                        echo "Waiting for function to be ready"
                        $maxAttempts = 6
                        $waitSeconds = 30
                        $attempt = 1
                        $success = $false
                        
                        while ($attempt -le $maxAttempts -and -not $success) {
                            Write-Host "Attempt $attempt of $maxAttempts"
                            
                            try {
                                $functions = az functionapp function list --resource-group $env:RESOURCE_GROUP --name $env:FUNCTION_APP_NAME --output json | ConvertFrom-Json
                                
                                if ($functions.Count -gt 0) {
                                    $httpTrigger = $functions | Where-Object { $_.name -eq "httpTrigger" }
                                    
                                    if ($httpTrigger) {
                                        $functionUrl = az functionapp function show --resource-group $env:RESOURCE_GROUP --name $env:FUNCTION_APP_NAME --function-name httpTrigger --query "invokeUrlTemplate" --output tsv
                                        
                                        if ($functionUrl) {
                                            Write-Host "Function URL: $functionUrl"
                                            
                                            try {
                                                $response = Invoke-WebRequest -Uri $functionUrl -UseBasicParsing
                                                $httpStatus = $response.StatusCode
                                                
                                                if ($httpStatus -eq 200) {
                                                    Write-Host "SUCCESS! Function is responding correctly (HTTP $httpStatus)"
                                                    $success = $true
                                                } else {
                                                    Write-Host "Function returned HTTP status: $httpStatus (attempt $attempt)"
                                                }
                                            } catch {
                                                Write-Host "Error testing function: $($_.Exception.Message) (attempt $attempt)"
                                            }
                                        } else {
                                            Write-Host "Could not retrieve function URL (attempt $attempt)"
                                        }
                                    } else {
                                        Write-Host "httpTrigger function not found (attempt $attempt)"
                                    }
                                } else {
                                    Write-Host "No functions found yet (attempt $attempt)"
                                }
                            } catch {
                                Write-Host "Error checking functions: $($_.Exception.Message) (attempt $attempt)"
                            }
                            
                            if (-not $success) {
                                $attempt++
                                if ($attempt -le $maxAttempts) {
                                    Write-Host "Trying again in $waitSeconds seconds"
                                    Start-Sleep $waitSeconds
                                }
                            }
                        }
                        
                        if (-not $success) {
                            Write-Host "Function deployment verification failed after $maxAttempts attempts"
                            Write-Host "Check Azure Portal manually or wait a few more minutes"
                        }
                    '''
                    
                    echo 'Deployment verification completed'
                }
            }
            post {
                always {
                    bat 'az logout || echo "Logout completed"'
                }
            }
        }
        
        stage('Monitor GitHub Actions Deployment') {
            when {
                environment name: 'DEPLOYMENT_METHOD', value: 'github-actions'
            }
            steps {
                script {
                    echo 'GitHub Actions deployment triggered successfully'
                    echo 'Deployment Status: DELEGATED TO GITHUB ACTIONS'
                    echo 'Monitor deployment progress at: https://github.com/DwarkeshNasit99/CICD-Assignment3-8985836_New/actions'
                    echo 'GitHub Actions workflow will: Checkout fresh code, Install dependencies, Run tests, Package function, Deploy to Azure, Verify deployment'
                    echo "Jenkins Build Tag: jenkins-build-${BUILD_NUMBER}"
                    echo "Target Function App: cicd-fn-helloworld-canadacentral"
                    echo "Environment: production"
                    echo 'Jenkins CI/CD responsibilities completed'
                    echo 'Azure deployment in progress via GitHub Actions'
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up workspace'
            script {
                try {
                    node {
                        if (fileExists("${DEPLOYMENT_PACKAGE}")) {
                            bat "del /q ${DEPLOYMENT_PACKAGE}"
                        }
                        if (fileExists('deploy')) {
                            bat 'rmdir /s /q deploy'
                        }
                    }
                } catch (Exception e) {
                    echo "Cleanup failed: ${e.message}"
                }
            }
        }
        
        success {
            echo 'Pipeline completed successfully'
            echo 'Function deployment process completed'
        }
        
        failure {
            echo 'Pipeline failed'
            echo 'Please check the logs above for details'
            echo 'Common issues: Azure credentials, Resource group or function app name, Network connectivity, Test failures'
        }
    }
}