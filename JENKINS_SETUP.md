# Jenkins CI/CD Pipeline Setup Guide

# Laravel Application with Kubernetes Deployment

## Overview

This guide sets up a complete CI/CD pipeline using Jenkins that:

- Polls Git repository every 5 minutes for changes
- Automatically builds and tests the Laravel application
- Sends email notifications on build failures (to srengty@gmail.com and committer)
- Deploys successfully tested builds using Ansible to Kubernetes

## Prerequisites

- Ubuntu/Debian Linux system
- Internet connection
- Git repository with your Laravel project
- Kubernetes cluster (minikube) running
- Laravel application already deployed in Kubernetes

## Installation Steps

### 1. Install Jenkins and Dependencies

```bash
# Run the automated installation script
./install-jenkins.sh
```

This script will install:

- Jenkins
- Java (OpenJDK 11)
- Docker
- kubectl
- minikube
- Ansible
- Node.js & NPM
- Composer

### 2. Initial Jenkins Setup

After installation completes:

1. **Access Jenkins Web Interface**

   - Open http://localhost:8080 in your browser
   - Use the initial admin password shown in the terminal

2. **Install Plugins**

   - Select "Install suggested plugins"
   - Additionally install these plugins:
     - Email Extension Plugin
     - Pipeline Plugin
     - Git Plugin
     - Docker Pipeline Plugin
     - Kubernetes Plugin

3. **Create Admin User**
   - Create your admin user account
   - Complete the initial setup wizard

### 3. Configure Email Notifications

1. **Go to Manage Jenkins > Configure System**

2. **Find "Extended E-mail Notification" section**

   - SMTP server: smtp.gmail.com
   - SMTP port: 587
   - Check "Use SMTP Authentication"
   - Username: your-email@gmail.com
   - Password: your-app-password (not regular password)
   - Check "Use TLS"
   - Default Recipients: srengty@gmail.com

3. **Test Email Configuration**
   - Use "Test configuration by sending test e-mail"

### 4. Add Credentials

1. **Go to Manage Jenkins > Manage Credentials**

2. **Add Kubeconfig File**
   - Click "Add Credentials"
   - Kind: "Secret file"
   - File: Upload your ~/.kube/config file
   - ID: kubeconfig-file
   - Description: Kubernetes Config File

### 5. Create Pipeline Job

1. **Click "New Item"**

   - Item name: Laravel-CI-CD-Pipeline
   - Select "Pipeline"
   - Click OK

2. **Configure Pipeline**

   - General: Check "GitHub project" if using GitHub
   - Build Triggers: Check "Poll SCM" and enter: H/5 \* \* \* \*
   - Pipeline:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: your-git-repository-url
     - Script Path: Jenkinsfile

3. **Save the configuration**

## Pipeline Features

### Automated Triggers

- **SCM Polling**: Checks for Git changes every 5 minutes
- **Webhook Support**: Can be configured for instant triggers

### Build Stages

1. **Checkout**: Downloads latest code from Git
2. **Build Dependencies**: Installs Composer and NPM packages in parallel
3. **Run Tests**: Executes Pest tests with SQLite database
4. **Docker Build**: Creates updated Docker image in minikube
5. **Deploy**: Uses Ansible to deploy to Kubernetes pods

### Email Notifications

- **Success**: Sent to srengty@gmail.com with deployment summary
- **Failure**: Sent to both srengty@gmail.com and the developer who committed the error
- **Rich HTML**: Includes build details, console links, and next steps

### Error Handling

- **Automatic Retries**: Retries failed builds once
- **Detailed Logging**: Full console output for debugging
- **Rollback Capability**: Pre-deployment backups created

## Testing the Pipeline

### 1. Manual Trigger

- Go to your pipeline job
- Click "Build Now"
- Monitor the console output

### 2. Git Commit Test

```bash
# Make a small change and commit
echo "# Test change" >> README.md
git add README.md
git commit -m "Test Jenkins pipeline"
git push origin main

# Jenkins will detect this change within 5 minutes
```

### 3. Intentional Failure Test

```bash
# Create a failing test to test email notifications
echo "<?php test('failing test', function() { expect(true)->toBe(false); });" > laravel/tests/Unit/FailingTest.php
git add laravel/tests/Unit/FailingTest.php
git commit -m "Test failure notifications"
git push origin main
```

## Monitoring and Maintenance

### Log Files

- Jenkins logs: /var/log/jenkins/jenkins.log
- Build logs: Available in Jenkins web interface
- Ansible logs: Generated during deployment

### Backup Strategy

- MySQL backups created before each deployment
- Jenkins configuration backed up automatically
- Git repository serves as source code backup

### Security Considerations

- Jenkins runs on localhost:8080 (configure firewall as needed)
- Kubernetes credentials stored securely in Jenkins
- Email passwords should use app-specific passwords

## Troubleshooting

### Common Issues

1. **Permission Denied (Docker)**

   ```bash
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

2. **kubectl Not Found**

   ```bash
   sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
   ```

3. **Email Not Sending**

   - Check SMTP settings
   - Verify app password for Gmail
   - Test with simple email first

4. **Ansible Connection Failed**
   ```bash
   # Test manually
   kubectl get pods -n laravel-app
   ansible kubernetes_pods -m ping
   ```

## File Structure

```
/mnt/mint-extra/dev-exam/
├── Jenkinsfile                     # Main pipeline definition
├── install-jenkins.sh              # Installation script
├── deploy-ansible.sh               # Deployment script
├── ansible/
│   ├── inventory/hosts.yml         # Ansible inventory
│   ├── playbooks/deploy-laravel.yml # Deployment playbook
│   └── vars/main.yml               # Variables
└── laravel/                        # Laravel application
```

## Support

For issues or questions:

1. Check Jenkins console output
2. Review log files
3. Test individual components (Docker, kubectl, Ansible)
4. Verify Kubernetes cluster status

The pipeline is designed to be robust and self-healing, with comprehensive error reporting and automatic cleanup.
