# Direct REST API deployment - most reliable, no dependencies
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ZipFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$AccessToken
)

Write-Host "🚀 Deploying Azure Function using REST API..."

try {
    # Get publishing credentials
    $credsUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$FunctionAppName/config/publishingcredentials/list"
    
    $headers = @{
        'Authorization' = "Bearer $AccessToken"
        'Content-Type' = 'application/json'
    }
    
    Write-Host "Getting publishing credentials..."
    $credsResponse = Invoke-RestMethod -Uri $credsUrl -Method POST -Headers $headers
    
    $publishingUsername = $credsResponse.properties.publishingUserName
    $publishingPassword = $credsResponse.properties.publishingPassword
    
    # Create basic auth header for Kudu
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($publishingUsername):$($publishingPassword)"))
    $kuduHeaders = @{
        'Authorization' = "Basic $base64AuthInfo"
        'Content-Type' = 'application/zip'
    }
    
    # Upload zip file to Kudu
    $kuduUrl = "https://$FunctionAppName.scm.azurewebsites.net/api/zipdeploy"
    
    Write-Host "Uploading deployment package to Kudu..."
    $zipBytes = [System.IO.File]::ReadAllBytes($ZipFilePath)
    
    $deployResponse = Invoke-RestMethod -Uri $kuduUrl -Method POST -Headers $kuduHeaders -Body $zipBytes
    
    Write-Host "✅ Deployment initiated successfully!"
    Write-Host "📦 Deployment ID: $($deployResponse.id)"
    
    # Check deployment status
    $statusUrl = "https://$FunctionAppName.scm.azurewebsites.net/api/deployments"
    
    $maxWait = 300 # 5 minutes
    $waitTime = 0
    $deployed = $false
    
    Write-Host "⏳ Monitoring deployment status..."
    
    while ($waitTime -lt $maxWait -and -not $deployed) {
        Start-Sleep -Seconds 15
        $waitTime += 15
        
        try {
            $statusResponse = Invoke-RestMethod -Uri $statusUrl -Headers @{'Authorization' = "Basic $base64AuthInfo"}
            $latestDeployment = $statusResponse | Sort-Object received_time -Descending | Select-Object -First 1
            
            if ($latestDeployment.status -eq 4) { # Success
                $deployed = $true
                Write-Host "✅ Deployment completed successfully!"
            } elseif ($latestDeployment.status -eq 3) { # Failed
                Write-Host "❌ Deployment failed!"
                Write-Host "Error: $($latestDeployment.message)"
                throw "Deployment failed"
            } else {
                Write-Host "⏳ Still deploying... Status: $($latestDeployment.status) ($waitTime/$maxWait seconds)"
            }
        } catch {
            Write-Host "⚠️ Could not check status, continuing to wait..."
        }
    }
    
    if (-not $deployed) {
        Write-Host "⚠️ Deployment timeout, but may still be in progress"
    }
    
    # Get function URL
    $functionUrl = "https://$FunctionAppName.azurewebsites.net/api/hello"
    Write-Host "🌐 Function URL: $functionUrl"
    
} catch {
    Write-Host "❌ REST API deployment failed: $($_.Exception.Message)"
    throw
}