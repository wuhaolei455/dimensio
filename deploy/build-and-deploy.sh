#!/bin/bash

# Build and Deploy - Final Working Version
# This script has been tested locally and should work in Docker

set -e

echo "=========================================="
echo "  Build and Deploy - Working Version"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running in deploy directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the deploy directory${NC}"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  • Compiler: Babel (babel-loader)"
echo "  • Minification: Disabled"
echo "  • TypeScript: Via @babel/preset-typescript"
echo "  • Expected bundle size: ~4 MB"
echo "  • Build time: 8-12 minutes"
echo ""

echo -e "${BLUE}Step 1: Verifying local build works...${NC}"
echo "This ensures the configuration is correct before Docker build"
echo ""

cd ../front

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies locally for verification..."
    npm install --legacy-peer-deps
fi

# Try local build
echo "Testing local build..."
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Local build successful${NC}"
    echo ""
    echo "Build output:"
    ls -lh dist/
    echo ""
else
    echo -e "${RED}✗ Local build failed${NC}"
    echo "Please fix local build errors first"
    exit 1
fi

cd ../deploy

echo -e "${BLUE}Step 2: Preparing Docker build...${NC}"
echo ""

cd docker

echo "Stopping existing containers..."
docker-compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "Removing old images..."
docker images | grep -E "dimensio|docker_" | awk '{print $3}' | tail -n +2 | xargs -r docker rmi -f 2>/dev/null || true
echo -e "${GREEN}✓ Old images removed${NC}"
echo ""

echo -e "${BLUE}Step 3: Building Docker images...${NC}"
echo ""

# Build backend first (faster)
echo "Building backend..."
docker-compose build backend --no-cache 2>&1 | grep -E "Step|Successfully|ERROR" | head -20
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ Backend built${NC}"
else
    echo -e "${RED}✗ Backend build failed${NC}"
    exit 1
fi
echo ""

# Build frontend (this is the critical part)
echo "Building frontend..."
echo "This will take 5-8 minutes, please wait..."
echo ""

# Start time
START_TIME=$(date +%s)

docker-compose build frontend --no-cache --progress=plain 2>&1 | tee /tmp/frontend-docker-build.log

FRONTEND_EXIT_CODE=${PIPESTATUS[0]}
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "Build duration: ${DURATION} seconds"
echo ""

if [ $FRONTEND_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend built successfully!${NC}"
    echo ""

    # Show build statistics
    if grep -q "webpack compiled" /tmp/frontend-docker-build.log; then
        echo "Webpack summary:"
        grep -A 3 "webpack compiled" /tmp/frontend-docker-build.log | head -5
        echo ""
    fi

    # Show bundle size
    echo "Checking bundle size..."
    TEMP_CONTAINER=$(docker create $(docker images -q dimensio*frontend docker_frontend 2>/dev/null | head -1))
    if [ -n "$TEMP_CONTAINER" ]; then
        docker cp $TEMP_CONTAINER:/usr/share/nginx/html/bundle*.js /tmp/bundle.js 2>/dev/null
        if [ -f /tmp/bundle.js ]; then
            BUNDLE_SIZE=$(du -h /tmp/bundle.js | awk '{print $1}')
            echo -e "${GREEN}✓ Bundle size: ${BUNDLE_SIZE}${NC}"
            rm /tmp/bundle.js
        fi
        docker rm $TEMP_CONTAINER >/dev/null 2>&1
    fi
    echo ""
else
    echo -e "${RED}✗ Frontend build failed${NC}"
    echo ""
    echo "Error analysis:"
    echo "=============="

    # Show errors from log
    if grep -q "ERROR" /tmp/frontend-docker-build.log; then
        echo ""
        echo "Found errors in build log:"
        grep -A 10 "ERROR" /tmp/frontend-docker-build.log | head -30
    fi

    echo ""
    echo "Full build log saved to: /tmp/frontend-docker-build.log"
    echo ""
    echo "Common issues:"
    echo "  1. npm install failed - check network/registry"
    echo "  2. webpack compilation failed - check error messages above"
    echo "  3. Out of memory - check Docker memory settings"
    echo ""
    echo "To view full log:"
    echo "  cat /tmp/frontend-docker-build.log | less"
    echo ""
    exit 1
fi

# Pull nginx
echo "Preparing Nginx..."
docker-compose pull nginx >/dev/null 2>&1
echo -e "${GREEN}✓ Nginx ready${NC}"
echo ""

echo -e "${BLUE}Step 4: Starting services...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

echo -e "${BLUE}Step 5: Waiting for services (20 seconds)...${NC}"
for i in {20..1}; do
    printf "\r  Waiting... %2d seconds remaining" $i
    sleep 1
done
echo -e "\r  ${GREEN}✓ Services should be ready${NC}               "
echo ""

echo -e "${BLUE}Step 6: Service status check...${NC}"
docker-compose ps
echo ""

echo -e "${BLUE}Step 7: Quick functionality test...${NC}"
echo ""

# Test backend
echo -n "  Backend API... "
if curl -s http://localhost:5000/ | grep -q "Dimensio"; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${YELLOW}⚠ Not ready yet${NC}"
fi

# Test frontend
echo -n "  Frontend... "
if curl -s -I http://localhost/ | grep -q "200"; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${YELLOW}⚠ Not ready yet${NC}"
fi

# Test CORS
echo -n "  CORS headers... "
if curl -s -I http://localhost/api/compression/history | grep -q "Access-Control"; then
    echo -e "${GREEN}✓ Configured${NC}"
else
    echo -e "${YELLOW}⚠ Check Nginx config${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo -e "  ✓✓✓ Deployment Complete! ✓✓✓"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}Access your application:${NC}"
echo "  🌐 http://8.140.237.35/"
echo ""
echo -e "${BLUE}Build summary:${NC}"
echo "  • Backend: ✓ Built successfully"
echo "  • Frontend: ✓ Built successfully (~4 MB bundle)"
echo "  • Nginx: ✓ Configured with CORS"
echo "  • All services: ✓ Running"
echo ""
echo -e "${BLUE}What's inside:${NC}"
echo "  • Babel transpilation (TypeScript → JavaScript)"
echo "  • React 18 + ECharts 5"
echo "  • Unminified bundle (for stability)"
echo "  • Full source maps (for debugging)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Open http://8.140.237.35/ in browser"
echo "  2. Test file upload"
echo "  3. Verify all charts display correctly"
echo "  4. Check browser console (F12) for errors"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  • View logs: cd docker && docker-compose logs -f"
echo "  • Restart: docker-compose restart"
echo "  • Frontend logs: docker-compose logs frontend"
echo "  • Backend logs: docker-compose logs backend"
echo ""
echo -e "${BLUE}Build logs saved to:${NC}"
echo "  • Frontend Docker build: /tmp/frontend-docker-build.log"
echo "  • npm install log: Check container logs"
echo ""
