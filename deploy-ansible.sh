#!/bin/bash

# Laravel Deployment Script using Ansible
# This script deploys the Laravel application to Kubernetes pod

set -e

echo "🚀 Starting Laravel deployment with Ansible..."

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible is not installed. Installing..."
    sudo apt update && sudo apt install -y ansible
fi

# Check if kubectl is working
if ! kubectl get pods -n laravel-app &> /dev/null; then
    echo "❌ kubectl is not working or Laravel pods are not running"
    echo "Please ensure your Kubernetes cluster is running and pods are available"
    exit 1
fi

# Get the current pod name
POD_NAME=$(kubectl get pods -n laravel-app -l app=laravel-app-single-pod -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ No Laravel pod found in laravel-app namespace"
    exit 1
fi

echo "✅ Found Laravel pod: $POD_NAME"

# Update the inventory with the actual pod name
sed -i "s/ansible_kubectl_pod=.*/ansible_kubectl_pod=$POD_NAME/" ansible/inventory/hosts.yml

echo "🔧 Updated Ansible inventory with pod name: $POD_NAME"

# Run the Ansible playbook
echo "📦 Running Ansible playbook..."
ansible-playbook ansible/playbooks/deploy-laravel.yml -v

echo "✅ Deployment completed!"
echo ""
echo "📊 You can check the application status with:"
echo "   kubectl logs -f -n laravel-app $POD_NAME -c web-server"
echo ""
echo "🌐 Access your application:"
echo "   minikube service laravel-single-pod-service -n laravel-app --url"