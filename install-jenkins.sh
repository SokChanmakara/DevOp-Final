#!/bin/bash

# Jenkins Installation and Setup Script for Ubuntu/Debian
# This script installs Jenkins, Docker, and configures the CI/CD pipeline

set -e

echo "🚀 Setting up Jenkins for Laravel CI/CD Pipeline"
echo "================================================"

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Java (required for Jenkins)
echo "☕ Installing OpenJDK 11..."
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
echo "🔧 Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
echo "🏗️ Installing Jenkins..."
sudo apt update
sudo apt install -y jenkins

# Install Docker (if not already installed)
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker jenkins
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install kubectl (if not already installed)
if ! command -v kubectl &> /dev/null; then
    echo "⎈ Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Install minikube (if not already installed)
if ! command -v minikube &> /dev/null; then
    echo "🎯 Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

# Install Ansible (if not already installed)
if ! command -v ansible &> /dev/null; then
    echo "🤖 Installing Ansible..."
    sudo apt install -y ansible
fi

# Install Node.js and NPM (if not already installed)
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js and NPM..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install Composer (if not already installed)
if ! command -v composer &> /dev/null; then
    echo "🎵 Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
fi

# Start and enable Jenkins
echo "🚀 Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins to apply group changes
sudo systemctl restart jenkins

# Get Jenkins initial admin password
echo ""
echo "✅ Jenkins installation completed!"
echo "=================================="
echo ""
echo "🔑 Jenkins Initial Admin Password:"
echo "$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
echo ""
echo "🌐 Jenkins Web Interface: http://localhost:8080"
echo ""
echo "📋 Next Steps:"
echo "1. Open http://localhost:8080 in your web browser"
echo "2. Use the initial admin password above to unlock Jenkins"
echo "3. Install suggested plugins"
echo "4. Create an admin user"
echo "5. Run the Jenkins configuration script: ./setup-jenkins-job.sh"
echo ""
echo "⚠️  Important: You may need to log out and log back in for Docker group changes to take effect"
echo ""

# Create Jenkins job configuration script
cat > setup-jenkins-job.sh << 'EOF'
#!/bin/bash

echo "🔧 Jenkins Job Configuration Helper"
echo "=================================="
echo ""
echo "After setting up Jenkins, follow these steps:"
echo ""
echo "1. 📧 Configure Email Notifications:"
echo "   - Go to Manage Jenkins > Configure System"
echo "   - Find 'Extended E-mail Notification' section"
echo "   - Set SMTP server (e.g., smtp.gmail.com:587 for Gmail)"
echo "   - Configure authentication"
echo "   - Test email configuration"
echo ""
echo "2. 🔑 Add Credentials:"
echo "   - Go to Manage Jenkins > Manage Credentials"
echo "   - Add 'Secret file' for kubeconfig (ID: kubeconfig-file)"
echo "   - Upload your ~/.kube/config file"
echo ""
echo "3. 📦 Install Required Plugins:"
echo "   - Go to Manage Jenkins > Manage Plugins"
echo "   - Install: 'Email Extension', 'Pipeline', 'Git', 'Docker Pipeline'"
echo ""
echo "4. 🏗️ Create New Pipeline Job:"
echo "   - Click 'New Item'"
echo "   - Enter name: 'Laravel-CI-CD-Pipeline'"
echo "   - Select 'Pipeline' and click OK"
echo "   - In Pipeline section, select 'Pipeline script from SCM'"
echo "   - Set SCM to 'Git'"
echo "   - Add your repository URL"
echo "   - Set Script Path to 'Jenkinsfile'"
echo "   - Save the job"
echo ""
echo "5. 🔄 Enable Polling:"
echo "   - The Jenkinsfile already includes 'pollSCM' trigger"
echo "   - Jenkins will check for changes every 5 minutes"
echo ""
echo "✅ Your CI/CD pipeline is ready!"
EOF

chmod +x setup-jenkins-job.sh

echo "📝 Jenkins job configuration helper created: ./setup-jenkins-job.sh"
echo "Run this script after Jenkins web setup is complete."