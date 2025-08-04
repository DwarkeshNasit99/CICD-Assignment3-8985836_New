// Alternative Deploy stage with multiple fallback methods
// Replace the current Deploy stage with this if ZIP deployment fails

stage('Deploy') {
    steps {
        script {
            echo '🚀 Deploying to Azure Functions with fallback methods...'
            
            // Azure login (same as current)
            bat '''
                echo Logging into Azure...
                az login --service-principal --username %AZURE_CLIENT_ID% --password %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%
                az account set --subscription %AZURE_SUBSCRIPTION_ID%
                echo Verifying login...
                az account show
            '''
            
            def deploymentSuccessful = false
            
            // Method 1: Standard ZIP deployment
            if (!deploymentSuccessful) {
                echo '📦 Trying Method 1: Standard ZIP deployment...'
                try {
                    bat """
                        echo Deploying using ZIP method...
                        az functionapp deployment source config-zip --resource-group %RESOURCE_GROUP% --name %FUNCTION_APP_NAME% --src %DEPLOYMENT_PACKAGE% --build-remote true
                    """
                    deploymentSuccessful = true
                    echo '✅ ZIP deployment successful!'
                } catch (Exception e) {
                    echo "❌ ZIP deployment failed: ${e.message}"
                }
            }
            
            // Method 2: Azure Functions Core Tools (if pre-installed)
            if (!deploymentSuccessful) {
                echo '🔧 Trying Method 2: Azure Functions Core Tools...'
                try {
                    bat '''
                        where func >nul 2>nul
                        if %errorlevel% equ 0 (
                            echo Core Tools found, deploying...
                            cd deploy
                            func azure functionapp publish %FUNCTION_APP_NAME% --build-remote
                            cd ..
                        ) else (
                            echo Core Tools not found, skipping this method
                            exit /b 1
                        )
                    '''
                    deploymentSuccessful = true
                    echo '✅ Core Tools deployment successful!'
                } catch (Exception e) {
                    echo "❌ Core Tools deployment failed: ${e.message}"
                }
            }
            
            // Method 3: PowerShell Az Module
            if (!deploymentSuccessful) {
                echo '💻 Trying Method 3: PowerShell Az Module...'
                try {
                    // Get access token for Az PowerShell
                    def accessToken = bat(
                        script: 'az account get-access-token --query "accessToken" --output tsv',
                        returnStdout: true
                    ).trim()
                    
                    powershell """
                        # Install Az module if needed
                        if (!(Get-Module -ListAvailable -Name Az.Websites)) {
                            Install-Module -Name Az.Websites -Force -AllowClobber -Scope CurrentUser
                        }
                        
                        # Deploy using Az module
                        Import-Module Az.Profile
                        Import-Module Az.Websites
                        
                        # Set context using access token
                        \$secureToken = ConvertTo-SecureString "${accessToken}" -AsPlainText -Force
                        Connect-AzAccount -AccessToken \$secureToken -AccountId "${AZURE_CLIENT_ID}"
                        Set-AzContext -SubscriptionId "${AZURE_SUBSCRIPTION_ID}"
                        
                        # Deploy
                        Publish-AzWebApp -ResourceGroupName "${RESOURCE_GROUP}" -Name "${FUNCTION_APP_NAME}" -ArchivePath "${DEPLOYMENT_PACKAGE}" -Force
                    """
                    deploymentSuccessful = true
                    echo '✅ PowerShell Az Module deployment successful!'
                } catch (Exception e) {
                    echo "❌ PowerShell Az Module deployment failed: ${e.message}"
                }
            }
            
            // Method 4: Direct REST API
            if (!deploymentSuccessful) {
                echo '🌐 Trying Method 4: Direct REST API...'
                try {
                    def accessToken = bat(
                        script: 'az account get-access-token --query "accessToken" --output tsv',
                        returnStdout: true
                    ).trim()
                    
                    powershell """
                        & "${WORKSPACE}\\scripts\\deploy-with-rest-api.ps1" `
                            -ResourceGroup "${RESOURCE_GROUP}" `
                            -FunctionAppName "${FUNCTION_APP_NAME}" `
                            -ZipFilePath "${DEPLOYMENT_PACKAGE}" `
                            -SubscriptionId "${AZURE_SUBSCRIPTION_ID}" `
                            -AccessToken "${accessToken}"
                    """
                    deploymentSuccessful = true
                    echo '✅ REST API deployment successful!'
                } catch (Exception e) {
                    echo "❌ REST API deployment failed: ${e.message}"
                }
            }
            
            // Method 5: Manual upload via Storage Account (last resort)
            if (!deploymentSuccessful) {
                echo '📁 Trying Method 5: Storage Account upload...'
                try {
                    bat """
                        echo Creating storage account for deployment...
                        az storage account create --name ${FUNCTION_APP_NAME}deploy --resource-group %RESOURCE_GROUP% --location canadacentral --sku Standard_LRS
                        
                        echo Uploading package to storage...
                        az storage blob upload --account-name ${FUNCTION_APP_NAME}deploy --container-name deployments --name latest.zip --file %DEPLOYMENT_PACKAGE% --auth-mode login
                        
                        echo Getting blob URL...
                        for /f "tokens=*" %%i in ('az storage blob url --account-name ${FUNCTION_APP_NAME}deploy --container-name deployments --name latest.zip --auth-mode login --output tsv') do set BLOB_URL=%%i
                        
                        echo Configuring function app to run from package...
                        az functionapp config appsettings set --name %FUNCTION_APP_NAME% --resource-group %RESOURCE_GROUP% --settings WEBSITE_RUN_FROM_PACKAGE="%BLOB_URL%"
                    """
                    deploymentSuccessful = true
                    echo '✅ Storage Account deployment successful!'
                } catch (Exception e) {
                    echo "❌ Storage Account deployment failed: ${e.message}"
                }
            }
            
            if (!deploymentSuccessful) {
                error('❌ All deployment methods failed!')
            }
            
            echo '✅ Deployment completed successfully using one of the fallback methods!'
        }
    }
    post {
        always {
            bat 'az logout || echo "Logout failed but continuing"'
        }
        success {
            echo '✅ Deploy stage completed successfully'
        }
        failure {
            echo '❌ Deploy stage failed - all methods exhausted'
        }
    }
}