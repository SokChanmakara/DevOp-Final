#!/bin/bash

# Load Balancer Deployment Script
# Deploys HAProxy load balancer with Laravel application

set -e

echo "🚀 Starting Load Balancer Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_status "Docker is running ✅"

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "docker-compose is not installed. Please install it first."
    exit 1
fi

print_status "Docker Compose is available ✅"

# Stop any existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans || true

# Build and start services
print_status "Building and starting services..."
docker-compose up -d --build

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check if HAProxy is running
if docker ps | grep -q "haproxy_loadbalancer"; then
    print_success "HAProxy Load Balancer is running ✅"
else
    print_error "HAProxy failed to start"
    exit 1
fi

# Check if web services are running
if docker ps | grep -q "nginx_server_devop"; then
    print_success "Nginx Web Server is running ✅"
else
    print_warning "Nginx Web Server is not running"
fi

# Check if database is running
if docker ps | grep -q "mysql_db_devop"; then
    print_success "MySQL Database is running ✅"
else
    print_warning "MySQL Database is not running"
fi

# Display service information
echo ""
echo "🎉 Load Balancer Deployment Complete!"
echo ""
echo "📊 Service Endpoints:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Main Website (Load Balanced):     http://localhost:8090"
echo "📈 HAProxy Stats Dashboard:          http://localhost:8091/stats"
echo "🗄️  MySQL Database:                  localhost:3306"
echo "🔒 SSH Access:                       localhost:2222 (user: devops, pass: devops123)"
echo ""
echo "🔧 Direct Access (Bypass Load Balancer):"
echo "🌐 Nginx Direct:                     http://localhost:8100"
echo "🗄️  MySQL Direct:                    localhost:3307"
echo "🔒 SSH Direct:                       localhost:2223"
echo ""
echo "📋 Load Balancer Features:"
echo "  • Round-robin load balancing for web traffic"
echo "  • Health checks for all services"
echo "  • Automatic failover to backup servers"
echo "  • Separate routing for API, admin, and static content"
echo "  • TCP load balancing for database and SSH"
echo ""

# Test the load balancer
print_status "Testing load balancer connectivity..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8090 | grep -q "200\|301\|302"; then
    print_success "Load balancer is responding to HTTP requests ✅"
else
    print_warning "Load balancer HTTP test failed - services may still be starting"
fi

# Check HAProxy stats
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8091/stats | grep -q "200"; then
    print_success "HAProxy stats dashboard is accessible ✅"
else
    print_warning "HAProxy stats dashboard is not yet accessible"
fi

echo ""
echo "🏁 Deployment script completed!"
echo "📖 Check the logs with: docker-compose logs -f haproxy"
echo "🔄 Restart services with: docker-compose restart"
echo "🛑 Stop services with: docker-compose down"