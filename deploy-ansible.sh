#!/bin/bash

# Jenkins-specific Ansible deployment script
# This script is called by Jenkins during the CI/CD pipeline

set -e

echo "🚀 Starting Jenkins-triggered deployment..."
echo "==========================================="

# Get current timestamp
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Get current pod name dynamically
echo "🔍 Finding current Laravel pod..."
POD_NAME=$(kubectl get pods -n laravel-app -l app=laravel-app-single-pod -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    echo "❌ Error: No Laravel pod found in laravel-app namespace"
    echo "Please ensure your Kubernetes cluster is running and pods are deployed"
    exit 1
fi

echo "✅ Found Laravel pod: $POD_NAME"

# Update Ansible inventory with current pod name
echo "🔧 Updating Ansible inventory..."
sed -i "s/laravel-app-single-pod-[a-zA-Z0-9-]*/${POD_NAME}/" ansible/inventory/hosts.yml

# Verify Ansible connectivity
echo "🔌 Testing Ansible connectivity..."
if ! ansible kubernetes_pods -m ping > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to Kubernetes pod via Ansible"
    echo "Please check your kubectl configuration and pod status"
    exit 1
fi

echo "✅ Ansible connectivity verified"

# Create backup before deployment
echo "💾 Creating pre-deployment backup..."
kubectl exec -n laravel-app ${POD_NAME} -c mysql-db -- mysqldump -u root -pHello@123 chanmakara-db > "backup_pre_deploy_${TIMESTAMP}.sql" 2>/dev/null || {
    echo "⚠️  Warning: Could not create MySQL backup (database might be empty)"
}

# Run Ansible playbook with logging
echo "📦 Executing Ansible deployment playbook..."
ANSIBLE_LOG_PATH="ansible_deploy_${TIMESTAMP}.log" ansible-playbook ansible/playbooks/deploy-laravel.yml -v

# Check deployment success
echo "🔍 Verifying deployment..."
if kubectl get pods -n laravel-app -l app=laravel-app-single-pod | grep -q "Running"; then
    echo "✅ Deployment verification successful - Pod is running"
    
    # Test application endpoint
    echo "🌐 Testing application endpoint..."
    sleep 10  # Wait for application to be ready
    
    # Get service URL
    SERVICE_URL=$(minikube service laravel-single-pod-service -n laravel-app --url 2>/dev/null | head -1 || echo "")
    
    if [ ! -z "$SERVICE_URL" ]; then
        if curl -s "$SERVICE_URL" > /dev/null; then
            echo "✅ Application endpoint is responding"
        else
            echo "⚠️  Warning: Application endpoint not responding yet (might need more time)"
        fi
    fi
else
    echo "❌ Deployment verification failed - Pod is not running"
    exit 1
fi

echo ""
echo "🎉 Jenkins deployment completed successfully!"
echo "============================================="
echo "📊 Deployment Summary:"
echo "  - Pod Name: $POD_NAME"
echo "  - Timestamp: $TIMESTAMP"
echo "  - Backup Created: backup_pre_deploy_${TIMESTAMP}.sql"
echo "  - Log File: ansible_deploy_${TIMESTAMP}.log"
echo ""

# Clean up old backup files (keep only last 5)
echo "🧹 Cleaning up old backup files..."
ls -t backup_pre_deploy_*.sql 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
ls -t ansible_deploy_*.log 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

echo "✅ Cleanup completed"