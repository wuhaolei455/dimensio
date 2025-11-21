#!/bin/bash

# Fix frontend build error
# This script specifically addresses the terser-webpack-plugin build error

set -e

echo "=========================================="
echo "  Fix Frontend Build Error"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in deploy directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the deploy directory${NC}"
    exit 1
fi

echo "This script will fix the frontend build error:"
echo "  - Update package.json to include terser-webpack-plugin"
echo "  - Update webpack.config.js with proper optimization settings"
echo "  - Update Dockerfile.frontend with increased memory limits"
echo ""

# Check if changes were already made
if ! grep -q "terser-webpack-plugin" ../front/package.json; then
    echo -e "${YELLOW}Warning: package.json updates not detected${NC}"
    echo "Please make sure the following changes have been made:"
    echo "  1. front/package.json - Added terser-webpack-plugin dependency"
    echo "  2. front/webpack.config.js - Updated with TerserPlugin configuration"
    echo "  3. deploy/docker/Dockerfile.frontend - Added NODE_OPTIONS environment"
    echo ""
    echo "These changes should have been made automatically."
    echo "If not, please check the files or contact support."
    echo ""
fi

echo "Step 1: Verify file changes..."
if grep -q "terser-webpack-plugin" ../front/package.json; then
    echo -e "${GREEN}✓ package.json updated${NC}"
else
    echo -e "${RED}✗ package.json not updated${NC}"
    exit 1
fi

if grep -q "TerserPlugin" ../front/webpack.config.js; then
    echo -e "${GREEN}✓ webpack.config.js updated${NC}"
else
    echo -e "${RED}✗ webpack.config.js not updated${NC}"
    exit 1
fi

if grep -q "NODE_OPTIONS" docker/Dockerfile.frontend; then
    echo -e "${GREEN}✓ Dockerfile.frontend updated${NC}"
else
    echo -e "${RED}✗ Dockerfile.frontend not updated${NC}"
    exit 1
fi
echo ""

echo "Step 2: Clean up old Docker images..."
cd docker
docker-compose down
echo -e "${GREEN}✓ Containers stopped${NC}"

# Remove old frontend image
docker images | grep -E "dimensio.*frontend|docker.*frontend" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
echo -e "${GREEN}✓ Old images removed${NC}"
echo ""

echo "Step 3: Rebuild frontend (this may take 5-10 minutes)..."
echo "  - Installing Node.js dependencies..."
echo "  - Compiling TypeScript..."
echo "  - Bundling with webpack..."
echo "  - Optimizing with terser..."
echo ""
echo "Please be patient, this is a production build..."
echo ""

# Build with verbose output
docker-compose build frontend --no-cache --progress=plain 2>&1 | tee /tmp/frontend-build.log

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Frontend built successfully!${NC}"
    echo ""

    echo "Step 4: Starting services..."
    docker-compose up -d
    echo -e "${GREEN}✓ Services started${NC}"
    echo ""

    echo "Step 5: Waiting for services (20 seconds)..."
    sleep 20
    echo ""

    echo "Step 6: Checking status..."
    docker-compose ps
    echo ""

    echo "=========================================="
    echo -e "${GREEN}  Build Fix Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Access: http://8.140.237.35/"
    echo "  2. Test functionality in the browser"
    echo "  3. Check for any errors in the console"
    echo ""
else
    echo ""
    echo -e "${RED}✗ Frontend build failed${NC}"
    echo ""
    echo "Build log saved to: /tmp/frontend-build.log"
    echo ""
    echo "Common issues:"
    echo "  1. Out of memory - Try building on a machine with more RAM"
    echo "  2. Network issues - Check npm registry connectivity"
    echo "  3. Dependency conflicts - Check package.json versions"
    echo ""
    echo "For detailed error analysis, check:"
    echo "  cat /tmp/frontend-build.log | grep -A 10 'ERROR'"
    echo ""
    exit 1
fi
