# Azure Functions CI/CD Pipeline with Jenkins

This project demonstrates a complete CI/CD pipeline for Azure Functions using Jenkins and GitHub Actions.

## Architecture

- **Jenkins**: Handles continuous integration (checkout, build, test)
- **GitHub Actions**: Handles continuous deployment (package, deploy to Azure)
- **Azure Functions**: Serverless function hosting using Node.js v4 programming model

## Prerequisites

### Azure Setup
1. Azure subscription with Function App created
2. Service principal with contributor access to the resource group
3. Function App named: `cicd-fn-helloworld-canadacentral`

### Jenkins Setup
1. Jenkins server with Node.js plugin installed
2. Azure CLI installed on Jenkins agent
3. Required Jenkins credentials configured

### GitHub Setup
1. GitHub repository with Actions enabled
2. Azure Function App publish profile secret configured

## Jenkins Credentials Configuration

Configure the following credentials in Jenkins (Manage Jenkins > Credentials):

- `AZURE_CLIENT_ID` (Secret text)
- `AZURE_CLIENT_SECRET` (Secret text)
- `AZURE_TENANT_ID` (Secret text)
- `AZURE_SUBSCRIPTION_ID` (Secret text)
- `AZURE_RESOURCE_GROUP` (Secret text)
- `AZURE_FUNCTION_APP_NAME` (Secret text)
- `GITHUB_TOKEN_PWD` (Username with password)

## GitHub Secrets Configuration

Add the following secret to your GitHub repository (Settings > Secrets and variables > Actions):

- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE`: Complete publish profile content from Azure Portal

## Function Structure

```
httpTrigger/
├── index.js          # Function implementation (Azure Functions v4)
├── function.json     # Function bindings and metadata
tests/
├── httpTrigger.test.js # Unit tests
package.json          # Project dependencies and configuration
host.json            # Function app configuration
```

## Deployment Process

1. **Automatic Trigger**: Push to main branch automatically triggers Jenkins build
2. **Continuous Integration**: Jenkins performs checkout, build, and test
3. **Deployment Trigger**: Jenkins triggers GitHub Actions workflow
4. **Continuous Deployment**: GitHub Actions packages and deploys to Azure
5. **Verification**: GitHub Actions verifies deployment success

## Automatic Pipeline Triggering

The pipeline supports two methods for automatic triggering:

### Method 1: SCM Polling (Currently Enabled)
- Jenkins polls GitHub repository every 2 minutes for changes
- Automatically triggers build when new commits are detected
- No additional configuration required

### Method 2: GitHub Webhook (Recommended for Production)
- Real-time triggering when code is pushed to GitHub
- More efficient than polling
- Requires webhook configuration in GitHub repository settings

## Running the Pipeline

### Automatic (Recommended)
1. Push code changes to the main branch
2. Jenkins automatically detects changes within 2 minutes
3. Pipeline starts automatically
4. Monitor progress in Jenkins console output
5. Monitor deployment in GitHub Actions tab
6. Verify function is accessible via Azure Portal

### Manual (For Testing)
1. Go to Jenkins dashboard
2. Click on your pipeline project
3. Click "Build Now"
4. Monitor pipeline execution

## Testing the Function

After successful deployment, test the function using:

### Basic Request
```
GET https://cicd-fn-helloworld-canadacentral.azurewebsites.net/api/hello?code=YOUR_FUNCTION_KEY
```

### Request with Parameter
```
GET https://cicd-fn-helloworld-canadacentral.azurewebsites.net/api/hello?name=YourName&code=YOUR_FUNCTION_KEY
```

### Expected Response
```json
{
  "message": "Hello, World! This Azure Function was deployed using Jenkins CI/CD Pipeline.",
  "timestamp": "2025-01-04T...",
  "environment": "production",
  "nodeVersion": "v20.x.x",
  "functionRuntime": "Azure Functions v4",
  "programmingModel": "Node.js v4",
  "deploymentMethod": "Jenkins CI/CD Pipeline"
}
```

## Pipeline Stages

1. **Checkout**: Get latest code from GitHub repository
2. **Build**: Install Node.js dependencies and build application
3. **Test**: Run unit tests with coverage reporting
4. **Prepare GitHub Actions**: Setup for GitHub Actions deployment
5. **Deploy**: Trigger GitHub Actions workflow for Azure deployment
6. **Monitor**: Display deployment status and monitoring links

## Troubleshooting

### Common Issues
- Verify all Jenkins credentials are configured correctly
- Ensure GitHub secret `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` is set
- Check Azure Function App is running and accessible
- Verify service principal has sufficient permissions

### Logs and Monitoring
- Jenkins: Check console output for CI pipeline logs
- GitHub Actions: Check Actions tab for deployment logs
- Azure: Check Function App logs in Azure Portal

## Project Structure

```
├── .github/workflows/
│   └── azure-deploy-triggered.yml    # GitHub Actions workflow
├── httpTrigger/
│   ├── index.js                      # Main function code
│   └── function.json                 # Function configuration
├── tests/
│   └── httpTrigger.test.js           # Unit tests
├── Jenkinsfile                       # Jenkins pipeline definition
├── package.json                      # Node.js project configuration
├── host.json                         # Azure Functions host configuration
└── README.md                         # This file
```

## Technology Stack

- **Language**: JavaScript (Node.js)
- **Framework**: Azure Functions v4
- **CI/CD**: Jenkins + GitHub Actions
- **Cloud**: Microsoft Azure
- **Testing**: Jest
- **Version Control**: Git/GitHub