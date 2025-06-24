#!/bin/bash

echo "Building Laravel web application Docker image..."
docker build -t laravel-web:latest .

echo "Creating Kubernetes namespace..."
kubectl apply -f k8s-namespace.yaml

echo "Creating ConfigMaps..."
kubectl apply -f k8s-configmaps.yaml

echo "Deploying to Kubernetes..."
kubectl apply -f k8s-deployment.yaml

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/laravel-web -n laravel-app
kubectl wait --for=condition=available --timeout=300s deployment/mysql-db -n laravel-app

echo "Getting service information..."
kubectl get services -n laravel-app

echo ""
echo "Deployment complete!"
echo "Access your application at:"
echo "- Web: http://localhost:30080"
echo "- SSH: ssh root@localhost -p 30022 (password: Hello@123)"
echo ""
echo "To check pod status: kubectl get pods -n laravel-app"
echo "To view logs: kubectl logs -f deployment/laravel-web -n laravel-app"