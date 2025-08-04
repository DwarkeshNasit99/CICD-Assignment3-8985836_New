# PowerShell script to manually install Azure Functions Core Tools
# Run this on Jenkins agent machine as Administrator

Write-Host "Installing Azure Functions Core Tools v4 manually..."

# Method 1: Direct download and install
$downloadUrl = "https://github.com/Azure/azure-functions-core-tools/releases/download/4.0.5907/Azure.Functions.Cli.win-x64.4.0.5907.zip"
$tempPath = "$env:TEMP\azure-func-tools.zip"
$installPath = "C:\azure-functions-core-tools"

try {
    # Create install directory
    if (!(Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force
    }

    # Download
    Write-Host "Downloading Azure Functions Core Tools..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing

    # Extract
    Write-Host "Extracting to $installPath..."
    Expand-Archive -Path $tempPath -DestinationPath $installPath -Force

    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$installPath*") {
        $newPath = "$currentPath;$installPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-Host "Added $installPath to system PATH"
    }

    # Verify installation
    & "$installPath\func.exe" --version
    Write-Host "✅ Azure Functions Core Tools installed successfully!"

} catch {
    Write-Host "❌ Installation failed: $($_.Exception.Message)"
    
    # Method 2: Chocolatey (if available)
    Write-Host "Trying Chocolatey installation..."
    try {
        choco install azure-functions-core-tools -y
        Write-Host "✅ Installed via Chocolatey!"
    } catch {
        Write-Host "❌ Chocolatey installation also failed"
        
        # Method 3: MSI installer
        Write-Host "Trying MSI installer..."
        $msiUrl = "https://go.microsoft.com/fwlink/?linkid=2174087"
        $msiPath = "$env:TEMP\azure-func-tools.msi"
        
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i", $msiPath, "/quiet" -Wait
        Write-Host "✅ Installed via MSI!"
    }
}

# Cleanup
if (Test-Path $tempPath) { Remove-Item $tempPath -Force }

Write-Host "Installation complete. Please restart Jenkins service or reboot machine."