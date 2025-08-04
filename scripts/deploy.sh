#!/bin/bash

# Azure Function Deployment Script
# This script can be used for manual deployment or testing

set -e

echo "🚀 Azure Function Deployment Script"
echo "===================================="

# Check if required environment variables are set
required_vars=("AZURE_CLIENT_ID" "AZURE_CLIENT_SECRET" "AZURE_TENANT_ID" "AZURE_SUBSCRIPTION_ID" "RESOURCE_GROUP" "FUNCTION_APP_NAME")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Environment variable $var is not set"
        echo "Please set all required environment variables:"
        echo "  - AZURE_CLIENT_ID"
        echo "  - AZURE_CLIENT_SECRET"  
        echo "  - AZURE_TENANT_ID"
        echo "  - AZURE_SUBSCRIPTION_ID"
        echo "  - RESOURCE_GROUP"
        echo "  - FUNCTION_APP_NAME"
        exit 1
    fi
done

echo "✅ All required environment variables are set"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Run tests
echo "🧪 Running tests..."
npm test

# Create deployment package
echo "📦 Creating deployment package..."
rm -rf deploy
mkdir -p deploy

# Copy files needed for deployment
cp -r src deploy/
cp package.json deploy/
cp host.json deploy/

# Create zip file
cd deploy
zip -r ../function-deployment.zip .
cd ..

echo "📦 Deployment package created: function-deployment.zip"

# Login to Azure
echo "🔑 Logging into Azure..."
az login --service-principal \
    --username $AZURE_CLIENT_ID \
    --password $AZURE_CLIENT_SECRET \
    --tenant $AZURE_TENANT_ID

az account set --subscription $AZURE_SUBSCRIPTION_ID

# Deploy to Azure Functions
echo "🚀 Deploying to Azure Functions..."
az functionapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP \
    --name $FUNCTION_APP_NAME \
    --src function-deployment.zip \
    --build-remote true

# Get function URL
echo "🌐 Getting function URL..."
FUNCTION_URL=$(az functionapp function show \
    --resource-group $RESOURCE_GROUP \
    --name $FUNCTION_APP_NAME \
    --function-name httpTrigger \
    --query "invokeUrlTemplate" \
    --output tsv 2>/dev/null || echo "")

if [ ! -z "$FUNCTION_URL" ]; then
    echo "✅ Deployment successful!"
    echo "🌐 Function URL: $FUNCTION_URL"
    
    # Test the deployed function
    echo "🧪 Testing deployed function..."
    sleep 10  # Wait for function to be ready
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FUNCTION_URL" || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ Function is responding correctly (HTTP $HTTP_STATUS)"
        echo "📝 Function response:"
        curl -s "$FUNCTION_URL" | jq . || curl -s "$FUNCTION_URL"
    else
        echo "⚠️  Function returned HTTP status: $HTTP_STATUS"
    fi
else
    echo "⚠️  Could not retrieve function URL"
fi

# Cleanup
echo "🧹 Cleaning up..."
rm -f function-deployment.zip
rm -rf deploy

# Logout
az logout

echo "✅ Deployment script completed!"