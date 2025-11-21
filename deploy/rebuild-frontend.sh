#!/bin/bash

echo "=== Rebuilding and Restarting Services ==="
echo ""

# Get the project directory
PROJECT_DIR=$(pwd)

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found. Please run this script from the project root."
    echo "Looking for docker-compose.yml in common locations..."

    # Try to find it
    if [ -d "/root/dimensio" ]; then
        PROJECT_DIR="/root/dimensio"
        cd "$PROJECT_DIR"
    elif [ -d "/home/*/dimensio" ]; then
        PROJECT_DIR=$(ls -d /home/*/dimensio | head -1)
        cd "$PROJECT_DIR"
    else
        echo "Cannot find project directory. Please cd to the project directory first."
        exit 1
    fi
fi

echo "Working in: $PROJECT_DIR"
echo ""

echo "1. Stopping current services..."
docker-compose down
echo ""

echo "2. Rebuilding frontend with fixed API endpoints..."
docker-compose build frontend --no-cache
echo ""

echo "3. Starting all services..."
docker-compose up -d
echo ""

echo "4. Waiting for services to be ready (10 seconds)..."
sleep 10
echo ""

echo "5. Checking service status..."
docker-compose ps
echo ""

echo "6. Checking container logs..."
echo ""
echo "=== Backend Logs (last 20 lines) ==="
docker-compose logs --tail=20 backend
echo ""
echo "=== Frontend Logs (last 20 lines) ==="
docker-compose logs --tail=20 frontend
echo ""
echo "=== Nginx Logs (last 20 lines) ==="
docker-compose logs --tail=20 nginx
echo ""

echo "7. Testing local connectivity..."
echo ""
echo "Test 1: API health check"
curl -s http://localhost:5000/api/ || echo "Backend not responding"
echo ""
echo ""

echo "Test 2: Nginx -> Backend proxy"
curl -s http://localhost/api/ -w "\nHTTP Status: %{http_code}\n" || echo "Nginx proxy failed"
echo ""

echo "Test 3: Frontend"
curl -s http://localhost/ -I | head -5
echo ""

echo "=== Rebuild Complete ==="
echo ""
echo "Next steps:"
echo "1. Open browser and visit: http://8.140.237.35/"
echo "2. Check browser console for any errors (F12)"
echo "3. Try uploading files or viewing compression history"
echo ""
echo "If you still see errors:"
echo "  - Run: docker-compose logs -f backend"
echo "  - Check backend is healthy: docker ps"
echo "  - Test API directly: curl http://localhost:5000/api/compression/history"
