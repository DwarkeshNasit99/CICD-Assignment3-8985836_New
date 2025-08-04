# PowerShell deployment using Az module instead of Core Tools
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ZipFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

Write-Host "🚀 Deploying Azure Function using PowerShell Az module..."

try {
    # Install Az module if not present
    if (!(Get-Module -ListAvailable -Name Az.Functions)) {
        Write-Host "Installing Az.Functions module..."
        Install-Module -Name Az.Functions -Force -AllowClobber -Scope CurrentUser
    }

    # Import required modules
    Import-Module Az.Profile
    Import-Module Az.Functions
    Import-Module Az.Storage

    # Set subscription context
    Set-AzContext -SubscriptionId $SubscriptionId

    # Method 1: Publish from folder (preferred)
    $deployFolder = Split-Path $ZipFilePath -Parent
    $tempExtractPath = Join-Path $deployFolder "temp-extract"
    
    # Extract zip for deployment
    if (Test-Path $tempExtractPath) {
        Remove-Item -Recurse -Force $tempExtractPath
    }
    Expand-Archive -Path $ZipFilePath -DestinationPath $tempExtractPath

    Write-Host "Deploying from extracted folder: $tempExtractPath"
    
    # Use Publish-AzWebApp for deployment
    Publish-AzWebApp -ResourceGroupName $ResourceGroup -Name $FunctionAppName -ArchivePath $ZipFilePath -Force

    Write-Host "✅ Deployment completed successfully!"

    # Get function URL
    $functionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroup -Name $FunctionAppName
    $functionUrl = "https://$($functionApp.DefaultHostName)/api/hello"
    Write-Host "🌐 Function URL: $functionUrl"

    # Cleanup
    if (Test-Path $tempExtractPath) {
        Remove-Item -Recurse -Force $tempExtractPath
    }

} catch {
    Write-Host "❌ PowerShell Az deployment failed: $($_.Exception.Message)"
    throw
}