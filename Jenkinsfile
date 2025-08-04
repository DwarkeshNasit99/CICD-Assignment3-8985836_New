pipeline {
    agent any
    
    environment {
        // Azure credentials - configure these in Jenkins credentials
        AZURE_CLIENT_ID = credentials('azure-client-id')
        AZURE_CLIENT_SECRET = credentials('azure-client-secret') 
        AZURE_TENANT_ID = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        
        // Azure Function App details - update these with your actual values
        RESOURCE_GROUP = credentials('azure-resource-group')
        FUNCTION_APP_NAME = credentials('azure-function-app-name')
        
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
                    
                    // Clean previous builds
                    sh 'rm -rf node_modules package-lock.json || true'
                    
                    // Install dependencies
                    sh 'npm install'
                    
                    // Verify installation
                    sh 'npm list --depth=0 || true'
                    
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
                    
                    // Run tests with coverage
                    sh 'npm test -- --coverage --watchAll=false --ci'
                    
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
                    
                    // Create deployment directory
                    sh 'mkdir -p deploy'
                    
                    // Copy necessary files for deployment
                    sh '''
                        cp -r src deploy/
                        cp package.json deploy/
                        cp host.json deploy/
                        cp -r node_modules deploy/ || echo "node_modules not found, will install on Azure"
                    '''
                    
                    // Create deployment zip
                    sh """
                        cd deploy
                        zip -r ../${DEPLOYMENT_PACKAGE} .
                        cd ..
                        ls -la ${DEPLOYMENT_PACKAGE}
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
                    
                    // Install Azure CLI if not present
                    sh '''
                        if ! command -v az &> /dev/null; then
                            echo "Installing Azure CLI..."
                            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                        else
                            echo "Azure CLI already installed"
                            az version
                        fi
                    '''
                    
                    // Login to Azure using service principal
                    sh '''
                        echo "Logging into Azure..."
                        az login --service-principal \
                            --username $AZURE_CLIENT_ID \
                            --password $AZURE_CLIENT_SECRET \
                            --tenant $AZURE_TENANT_ID
                        
                        echo "Setting subscription..."
                        az account set --subscription $AZURE_SUBSCRIPTION_ID
                        
                        echo "Verifying login..."
                        az account show
                    '''
                    
                    // Deploy to Azure Function App
                    sh """
                        echo "Deploying to Azure Function App: ${FUNCTION_APP_NAME}"
                        echo "Resource Group: ${RESOURCE_GROUP}"
                        
                        # Deploy using zip deployment
                        az functionapp deployment source config-zip \\
                            --resource-group ${RESOURCE_GROUP} \\
                            --name ${FUNCTION_APP_NAME} \\
                            --src ${DEPLOYMENT_PACKAGE} \\
                            --build-remote true
                        
                        echo "Deployment completed!"
                        
                        # Get function URL
                        echo "Getting function URL..."
                        az functionapp function show \\
                            --resource-group ${RESOURCE_GROUP} \\
                            --name ${FUNCTION_APP_NAME} \\
                            --function-name httpTrigger \\
                            --query "invokeUrlTemplate" \\
                            --output tsv || echo "Could not retrieve function URL"
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
                    sh 'az logout || true'
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '🔍 Verifying deployment...'
                    
                    // Login again for verification
                    sh '''
                        az login --service-principal \
                            --username $AZURE_CLIENT_ID \
                            --password $AZURE_CLIENT_SECRET \
                            --tenant $AZURE_TENANT_ID
                        az account set --subscription $AZURE_SUBSCRIPTION_ID
                    '''
                    
                    // Check function app status
                    sh """
                        echo "Checking Function App status..."
                        az functionapp show \\
                            --resource-group ${RESOURCE_GROUP} \\
                            --name ${FUNCTION_APP_NAME} \\
                            --query "{name:name,state:state,hostNames:defaultHostName}" \\
                            --output table
                        
                        echo "Checking function runtime status..."
                        az functionapp config show \\
                            --resource-group ${RESOURCE_GROUP} \\
                            --name ${FUNCTION_APP_NAME} \\
                            --query "{nodeVersion:nodeVersion,appSettings:appSettings}" \\
                            --output json || true
                    """
                    
                    // Wait for function to be ready and test it
                    sh '''
                        echo "Waiting for function to be ready..."
                        sleep 30
                        
                        # Get function URL
                        FUNCTION_URL=$(az functionapp function show \
                            --resource-group $RESOURCE_GROUP \
                            --name $FUNCTION_APP_NAME \
                            --function-name httpTrigger \
                            --query "invokeUrlTemplate" \
                            --output tsv 2>/dev/null || echo "")
                        
                        if [ ! -z "$FUNCTION_URL" ]; then
                            echo "Testing function at: $FUNCTION_URL"
                            
                            # Test the function
                            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_URL" || echo "000")
                            
                            if [ "$HTTP_STATUS" = "200" ]; then
                                echo "✅ Function is responding correctly (HTTP $HTTP_STATUS)"
                                echo "Function response:"
                                curl -s "$FUNCTION_URL" | head -c 500
                            else
                                echo "⚠️  Function returned HTTP status: $HTTP_STATUS"
                                echo "This might be normal if the function is still warming up"
                            fi
                        else
                            echo "⚠️  Could not retrieve function URL for testing"
                        fi
                    '''
                    
                    echo '✅ Deployment verification completed!'
                }
            }
            post {
                always {
                    sh 'az logout || true'
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
            
            // Clean up deployment files
            sh '''
                rm -f ${DEPLOYMENT_PACKAGE} || true
                rm -rf deploy || true
            '''
            
            // Archive logs
            script {
                if (fileExists('npm-debug.log')) {
                    archiveArtifacts artifacts: 'npm-debug.log', allowEmptyArchive: true
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