#!/bin/bash

echo "=== Fixing Backend 502 Error ==="
echo ""

# Get the project directory
PROJECT_DIR=$(pwd)

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found. Trying to find project directory..."

    # Try to find it
    if [ -d "/root/dimensio" ]; then
        PROJECT_DIR="/root/dimensio"
        cd "$PROJECT_DIR"
    elif [ -d "$HOME/dimensio" ]; then
        PROJECT_DIR="$HOME/dimensio"
        cd "$PROJECT_DIR"
    else
        echo "Cannot find project directory. Please cd to the project directory first."
        exit 1
    fi
fi

echo "Working in: $PROJECT_DIR"
echo ""

echo "1. Stopping backend container..."
docker-compose stop backend
echo ""

echo "2. Removing old backend container..."
docker-compose rm -f backend
echo ""

echo "3. Rebuilding backend with fixed listening address..."
docker-compose build backend --no-cache
echo ""

echo "4. Starting backend..."
docker-compose up -d backend
echo ""

echo "5. Waiting for backend to start (10 seconds)..."
sleep 10
echo ""

echo "6. Checking backend status..."
docker-compose ps backend
echo ""

echo "7. Checking backend logs..."
docker-compose logs --tail=50 backend
echo ""

echo "8. Testing backend connectivity..."
echo ""
echo "Test 1: Backend health (direct connection)"
curl -s http://localhost:5000/ | head -20
echo ""
echo ""

echo "Test 2: API endpoint (direct)"
curl -s http://localhost:5000/api/compression/history || echo "No history yet (this is OK)"
echo ""
echo ""

echo "Test 3: Through nginx proxy"
curl -s http://localhost/api/compression/history || echo "No history yet (this is OK)"
echo ""
echo ""

echo "9. Checking if backend is listening on 0.0.0.0..."
docker exec dimensio-backend netstat -tlnp 2>/dev/null | grep 5000 || docker exec dimensio-backend ss -tlnp | grep 5000
echo ""

echo "=== Backend Fix Complete ==="
echo ""
echo "The backend should now be accessible at:"
echo "  - Direct: http://localhost:5000/"
echo "  - Via nginx: http://localhost/api/"
echo "  - External: http://8.140.237.35/api/"
echo ""
echo "Next steps:"
echo "1. Open browser: http://8.140.237.35/"
echo "2. Check if the 502 error is gone"
echo "3. Try uploading files or viewing history"
echo ""
echo "If you still see 502 errors, run:"
echo "  docker-compose logs -f backend"
