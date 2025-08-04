#!/bin/bash

# Jenkins Setup Script for Ubuntu/Debian
# This script installs Jenkins and required plugins for Azure CI/CD

set -e

echo "🔧 Jenkins Setup Script for Azure Functions CI/CD"
echo "=================================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update -y

# Install Java (required for Jenkins)
echo "☕ Installing Java 11..."
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
echo "📦 Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
echo "🔧 Installing Jenkins..."
sudo apt update -y
sudo apt install -y jenkins

# Start and enable Jenkins
echo "🚀 Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Node.js (required for Azure Functions)
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Azure CLI
echo "☁️  Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install additional tools
echo "🛠️  Installing additional tools..."
sudo apt install -y git curl wget zip unzip jq

# Configure firewall (if UFW is enabled)
if sudo ufw status | grep -q "Status: active"; then
    echo "🔥 Configuring firewall..."
    sudo ufw allow 8080/tcp
fi

# Get Jenkins initial password
echo "🔑 Getting Jenkins initial admin password..."
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "✅ Jenkins installation completed!"
    echo ""
    echo "=========================================="
    echo "🎉 JENKINS SETUP COMPLETED!"
    echo "=========================================="
    echo "🌐 Jenkins URL: http://localhost:8080"
    echo "🔑 Initial Admin Password: $INITIAL_PASSWORD"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Open http://localhost:8080 in your browser"
    echo "2. Enter the initial admin password: $INITIAL_PASSWORD"
    echo "3. Install suggested plugins"
    echo "4. Create your first admin user"
    echo "5. Install additional plugins:"
    echo "   - GitHub Plugin"
    echo "   - Pipeline Plugin"
    echo "   - NodeJS Plugin"
    echo "   - Azure CLI Plugin"
    echo "6. Configure GitHub integration"
    echo "7. Add Azure credentials"
    echo ""
    echo "🔧 Installed Software Versions:"
    echo "   - Java: $(java -version 2>&1 | head -n 1)"
    echo "   - Node.js: $(node --version)"
    echo "   - npm: $(npm --version)"
    echo "   - Azure CLI: $(az --version | head -n 1)"
    echo "   - Git: $(git --version)"
    echo ""
    echo "📚 For detailed configuration instructions, see:"
    echo "   - Jenkins documentation: https://www.jenkins.io/doc/"
    echo "   - Azure Functions documentation: https://docs.microsoft.com/en-us/azure/azure-functions/"
    echo ""
else
    echo "⚠️  Could not find Jenkins initial password file."
    echo "   Please check Jenkins logs: sudo journalctl -u jenkins"
fi

echo "✅ Jenkins setup script completed!"