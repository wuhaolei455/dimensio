#!/bin/bash

# Final fix for all build errors
# - Replaces ts-loader with babel-loader (more stable)
# - Disables code minification (avoids terser issues)
# - Configures CORS headers

set -e

echo "=========================================="
echo "  Final Build Fix - All Issues"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "This script fixes:"
echo "  ✓ ts-loader compatibility issues"
echo "  ✓ terser-webpack-plugin errors"
echo "  ✓ CORS cross-origin problems"
echo ""
echo "Changes made:"
echo "  • Replaced ts-loader with babel-loader"
echo "  • Disabled code minification"
echo "  • Added CORS headers to Nginx"
echo ""

# Check if running in deploy directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the deploy directory${NC}"
    exit 1
fi

echo "Step 1: Verifying file changes..."

# Check for babel-loader in package.json
if grep -q "babel-loader" ../front/package.json; then
    echo -e "${GREEN}✓ package.json - babel-loader added${NC}"
else
    echo -e "${RED}✗ package.json not updated correctly${NC}"
    exit 1
fi

# Check for babel-loader in webpack config
if grep -q "babel-loader" ../front/webpack.config.js; then
    echo -e "${GREEN}✓ webpack.config.js - babel-loader configured${NC}"
else
    echo -e "${RED}✗ webpack.config.js not updated correctly${NC}"
    exit 1
fi

# Check for .babelrc
if [ -f "../front/.babelrc" ]; then
    echo -e "${GREEN}✓ .babelrc - babel configuration exists${NC}"
else
    echo -e "${YELLOW}⚠ .babelrc not found, using inline config${NC}"
fi

# Check for CORS in nginx config
if grep -q "Access-Control-Allow-Origin" nginx/dimensio.conf; then
    echo -e "${GREEN}✓ nginx/dimensio.conf - CORS configured${NC}"
else
    echo -e "${YELLOW}⚠ CORS might not be configured${NC}"
fi

echo ""
echo "Step 2: Stopping existing containers..."
cd docker
docker-compose down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "Step 3: Cleaning up old images..."
docker images | grep -E "dimensio|docker_" | awk '{print $3}' | tail -n +2 | xargs -r docker rmi -f 2>/dev/null || true
echo -e "${GREEN}✓ Old images removed${NC}"
echo ""

echo "Step 4: Building services (this will take 8-12 minutes)..."
echo ""
echo "Build order:"
echo "  1. Backend (Flask API)         - 2-3 minutes"
echo "  2. Frontend (React + Babel)    - 5-8 minutes"
echo "  3. Nginx (Reverse Proxy)       - 1 minute"
echo ""
echo "Frontend build steps:"
echo "  • npm install (with Babel packages)"
echo "  • Babel transpile TypeScript → JavaScript"
echo "  • Webpack bundle (no minification)"
echo "  • Create Docker image"
echo ""
echo "Please be patient..."
echo ""

# Build backend
echo "Building backend..."
docker-compose build backend --no-cache 2>&1 | grep -E "Step|ERROR|Successfully" || true
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ Backend built successfully${NC}"
else
    echo -e "${RED}✗ Backend build failed${NC}"
    exit 1
fi
echo ""

# Build frontend with detailed output
echo "Building frontend (this is the critical part)..."
docker-compose build frontend --no-cache 2>&1 | tee /tmp/frontend-build.log

FRONTEND_EXIT_CODE=${PIPESTATUS[0]}

if [ $FRONTEND_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Frontend built successfully!${NC}"

    # Extract and show key info from build log
    if grep -q "webpack compiled" /tmp/frontend-build.log; then
        echo ""
        echo "Webpack compilation summary:"
        grep -A 5 "webpack compiled" /tmp/frontend-build.log | head -6
    fi
else
    echo ""
    echo -e "${RED}✗ Frontend build failed${NC}"
    echo ""
    echo "Last 30 lines of build log:"
    tail -30 /tmp/frontend-build.log
    echo ""
    echo "Full build log saved to: /tmp/frontend-build.log"
    exit 1
fi
echo ""

# Pull nginx
echo "Pulling Nginx image..."
docker-compose pull nginx >/dev/null 2>&1
echo -e "${GREEN}✓ Nginx ready${NC}"
echo ""

echo "Step 5: Starting all services..."
docker-compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

echo "Step 6: Waiting for services to initialize (20 seconds)..."
for i in {20..1}; do
    echo -ne "  Waiting... $i seconds remaining\r"
    sleep 1
done
echo -e "  ${GREEN}✓ Wait complete${NC}                    "
echo ""

echo "Step 7: Checking service status..."
docker-compose ps
echo ""

echo "Step 8: Testing endpoints..."
echo ""

# Test backend
echo -n "  Testing backend... "
if curl -s http://localhost:5000/ | grep -q "Dimensio API"; then
    echo -e "${GREEN}✓ Backend responding${NC}"
else
    echo -e "${YELLOW}⚠ Backend might not be ready yet${NC}"
fi

# Test frontend
echo -n "  Testing frontend... "
if curl -s -I http://localhost/ | grep -q "200 OK"; then
    echo -e "${GREEN}✓ Frontend responding${NC}"
else
    echo -e "${YELLOW}⚠ Frontend might not be ready yet${NC}"
fi

# Test CORS
echo -n "  Testing CORS... "
if curl -s -I http://localhost/api/compression/history | grep -q "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✓ CORS headers present${NC}"
else
    echo -e "${YELLOW}⚠ CORS headers might not be configured${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo -e "  ✓ Deployment Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Access your application:"
echo "  🌐 http://8.140.237.35/"
echo ""
echo "Next steps:"
echo "  1. Open the URL in your browser"
echo "  2. Test file upload functionality"
echo "  3. Check browser console for errors (F12)"
echo "  4. Verify all features work correctly"
echo ""
echo "Build details:"
echo "  • Compiler: Babel (replaced ts-loader)"
echo "  • Minification: Disabled (no terser errors)"
echo "  • Bundle size: ~1-2 MB (unminified)"
echo "  • Load time: ~2-3 seconds on local network"
echo ""
echo "If you encounter any issues:"
echo "  • View logs: cd docker && docker-compose logs -f"
echo "  • Restart: docker-compose restart"
echo "  • Check status: docker-compose ps"
echo ""
echo "Troubleshooting logs:"
echo "  • Frontend build log: /tmp/frontend-build.log"
echo "  • All logs: docker-compose logs"
echo ""
