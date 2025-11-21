#!/bin/bash

# Fix CORS issue for remote access
# This script rebuilds and restarts the services with proper CORS configuration

set -e

echo "=========================================="
echo "  Fix CORS Issue for Remote Access"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in deploy directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the deploy directory${NC}"
    exit 1
fi

echo "Step 1: Stopping existing containers..."
cd docker
docker-compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "Step 2: Rebuilding services (this may take a few minutes)..."
echo "  - Building backend with CORS support..."
docker-compose build backend --no-cache
echo -e "${GREEN}✓ Backend built${NC}"

echo "  - Building frontend..."
docker-compose build frontend --no-cache
echo -e "${GREEN}✓ Frontend built${NC}"

echo "  - Pulling Nginx image..."
docker-compose pull nginx
echo -e "${GREEN}✓ Nginx ready${NC}"
echo ""

echo "Step 3: Starting all services..."
docker-compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

echo "Step 4: Waiting for services to be ready (20 seconds)..."
sleep 20
echo -e "${GREEN}✓ Services should be ready${NC}"
echo ""

echo "Step 5: Checking service status..."
docker-compose ps
echo ""

echo "Step 6: Testing CORS configuration..."
echo ""

# Get the server IP (from nginx config or environment)
SERVER_IP="8.140.237.35"

echo "Testing backend CORS headers..."
curl -s -I "http://localhost:5000/api/compression/history" | grep -i "access-control" || echo "  Warning: Direct backend access may not show CORS headers"
echo ""

echo "Testing through Nginx (this should work)..."
curl -s -I "http://localhost/api/compression/history" | grep -i "access-control" || echo "  Warning: CORS headers not found"
echo ""

echo "=========================================="
echo -e "${GREEN}  Fix Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Access the application from external browser:"
echo "     http://${SERVER_IP}/"
echo ""
echo "  2. Open browser Developer Tools (F12)"
echo "     - Go to Network tab"
echo "     - Try uploading files or viewing history"
echo "     - Check that requests to /api/ succeed"
echo ""
echo "  3. If issues persist:"
echo "     - Check browser console for errors"
echo "     - Check Nginx logs: docker-compose logs nginx"
echo "     - Check backend logs: docker-compose logs backend"
echo ""
echo "Troubleshooting commands:"
echo "  - View all logs: docker-compose logs -f"
echo "  - View Nginx logs: docker-compose logs -f nginx"
echo "  - View backend logs: docker-compose logs -f backend"
echo "  - View frontend logs: docker-compose logs -f frontend"
echo "  - Restart services: docker-compose restart"
echo "  - Stop services: docker-compose down"
echo ""
