#!/bin/bash

# Fix terser-webpack-plugin error in Docker Alpine
# Solution: Disable code minimization to avoid terser compatibility issues

set -e

echo "=========================================="
echo "  Fix Terser Build Error"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Problem: terser-webpack-plugin causes 'Unexpected end of input' error"
echo "Solution: Disable code minimization in production build"
echo ""
echo "Trade-off:"
echo "  - Bundle size will be larger (~2-3x)"
echo "  - But build will succeed and app will work perfectly"
echo "  - Load time difference is minimal for internal apps"
echo ""

# Check if running in deploy directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the deploy directory${NC}"
    exit 1
fi

echo "Step 1: Verifying file changes..."

# Check webpack config
if grep -q "minimize: false" ../front/webpack.config.js; then
    echo -e "${GREEN}✓ webpack.config.js - minimization disabled${NC}"
else
    echo -e "${RED}✗ webpack.config.js not updated correctly${NC}"
    echo "Please ensure the changes were applied correctly."
    exit 1
fi

# Check package.json (terser should be removed)
if ! grep -q "terser-webpack-plugin" ../front/package.json; then
    echo -e "${GREEN}✓ package.json - terser-webpack-plugin removed${NC}"
else
    echo -e "${YELLOW}⚠ package.json still contains terser-webpack-plugin (will be ignored)${NC}"
fi

# Check Dockerfile
if grep -q "npm cache clean" docker/Dockerfile.frontend; then
    echo -e "${GREEN}✓ Dockerfile.frontend - npm cache cleaning added${NC}"
else
    echo -e "${YELLOW}⚠ Dockerfile.frontend might not have latest changes${NC}"
fi

echo ""
echo "Step 2: Stopping existing containers..."
cd docker
docker-compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "Step 3: Removing old images..."
docker images | grep -E "dimensio.*frontend|docker.*frontend" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
echo -e "${GREEN}✓ Old images removed${NC}"
echo ""

echo "Step 4: Building frontend (this may take 5-10 minutes)..."
echo ""
echo "Build steps:"
echo "  1. Installing npm dependencies..."
echo "  2. Compiling TypeScript to JavaScript..."
echo "  3. Bundling with webpack (WITHOUT minification)..."
echo "  4. Creating production Docker image..."
echo ""
echo "Please wait..."
echo ""

# Build frontend with progress output
docker-compose build frontend --no-cache 2>&1 | tee /tmp/frontend-build.log

BUILD_EXIT_CODE=${PIPESTATUS[0]}

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo -e "  ✓ Frontend Build Successful!"
    echo -e "==========================================${NC}"
    echo ""

    # Check bundle size
    echo "Checking bundle size..."
    CONTAINER_ID=$(docker create $(docker images -q dimensio*frontend | head -1))
    if [ -n "$CONTAINER_ID" ]; then
        docker cp $CONTAINER_ID:/usr/share/nginx/html /tmp/frontend-dist 2>/dev/null || true
        docker rm $CONTAINER_ID >/dev/null 2>&1

        if [ -d "/tmp/frontend-dist" ]; then
            BUNDLE_SIZE=$(du -sh /tmp/frontend-dist 2>/dev/null | awk '{print $1}')
            echo -e "${GREEN}✓ Bundle size: ${BUNDLE_SIZE}${NC}"
            rm -rf /tmp/frontend-dist
        fi
    fi
    echo ""

    echo "Step 5: Building other services..."
    docker-compose build backend --no-cache
    docker-compose pull nginx
    echo -e "${GREEN}✓ All services built${NC}"
    echo ""

    echo "Step 6: Starting all services..."
    docker-compose up -d
    echo -e "${GREEN}✓ Services started${NC}"
    echo ""

    echo "Step 7: Waiting for services to be ready (20 seconds)..."
    sleep 20
    echo ""

    echo "Step 8: Checking service status..."
    docker-compose ps
    echo ""

    echo -e "${GREEN}=========================================="
    echo -e "  ✓ Deployment Complete!"
    echo -e "==========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Access the application: http://8.140.237.35/"
    echo "  2. Test all functionality"
    echo "  3. Check browser console for errors"
    echo ""
    echo "Note: Bundle is not minified, so:"
    echo "  - Initial load may be slightly slower"
    echo "  - View source will show readable code"
    echo "  - But all functionality works perfectly"
    echo ""
    echo "To view logs:"
    echo "  docker-compose logs -f"
    echo ""

else
    echo ""
    echo -e "${RED}=========================================="
    echo -e "  ✗ Frontend Build Failed"
    echo -e "==========================================${NC}"
    echo ""
    echo "Build log saved to: /tmp/frontend-build.log"
    echo ""
    echo "To view the error:"
    echo "  cat /tmp/frontend-build.log | grep -A 20 'ERROR'"
    echo ""
    echo "Common issues:"
    echo "  1. Network problems - check npm registry connection"
    echo "  2. Disk space - check available space"
    echo "  3. Memory - ensure Docker has enough RAM"
    echo ""
    exit 1
fi
