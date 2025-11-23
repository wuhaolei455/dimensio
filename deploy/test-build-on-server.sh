#!/bin/bash

# Frontend Build Test Script
# Run this on the server to test if the build configuration works

set -e

echo "=========================================="
echo "  Frontend Build Test - Server Version"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Find the front directory
if [ -d "/root/dimensio/front" ]; then
    FRONT_DIR="/root/dimensio/front"
elif [ -d "../front" ]; then
    FRONT_DIR="../front"
else
    echo -e "${RED}✗ Cannot find front directory${NC}"
    exit 1
fi

echo -e "${BLUE}Frontend directory: ${FRONT_DIR}${NC}"
echo ""

cd "$FRONT_DIR"

# Step 1: Clean
echo -e "${BLUE}Step 1: Cleaning old files...${NC}"
rm -rf node_modules dist package-lock.json 2>/dev/null || true
echo -e "${GREEN}✓ Cleaned${NC}"
echo ""

# Step 2: Install
echo -e "${BLUE}Step 2: Installing dependencies...${NC}"
echo "This may take 2-3 minutes..."
npm install --legacy-peer-deps 2>&1 | tee /tmp/npm-install.log | tail -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${RED}✗ npm install failed${NC}"
    echo "Full log: /tmp/npm-install.log"
    exit 1
fi
echo ""

# Step 3: Verify dependencies
echo -e "${BLUE}Step 3: Verifying key dependencies...${NC}"

check_dep() {
    if [ -d "node_modules/$1" ]; then
        echo -e "  ${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 - MISSING"
        return 1
    fi
}

ALL_DEPS_OK=true
check_dep "webpack" || ALL_DEPS_OK=false
check_dep "webpack-cli" || ALL_DEPS_OK=false
check_dep "babel-loader" || ALL_DEPS_OK=false
check_dep "@babel/core" || ALL_DEPS_OK=false
check_dep "@babel/preset-env" || ALL_DEPS_OK=false
check_dep "@babel/preset-react" || ALL_DEPS_OK=false
check_dep "@babel/preset-typescript" || ALL_DEPS_OK=false
check_dep "react" || ALL_DEPS_OK=false
check_dep "react-dom" || ALL_DEPS_OK=false

if [ "$ALL_DEPS_OK" = false ]; then
    echo -e "${RED}✗ Some dependencies are missing${NC}"
    exit 1
fi
echo ""

# Step 4: Show configuration
echo -e "${BLUE}Step 4: Checking configuration files...${NC}"

if [ -f "package.json" ]; then
    echo "  ✓ package.json exists"
    echo "    Build script:"
    cat package.json | grep -A 1 '"build"' | sed 's/^/      /'
else
    echo -e "  ${RED}✗ package.json missing${NC}"
    exit 1
fi

if [ -f "webpack.config.js" ]; then
    echo "  ✓ webpack.config.js exists"
else
    echo -e "  ${RED}✗ webpack.config.js missing${NC}"
    exit 1
fi

if [ -f ".babelrc" ]; then
    echo "  ✓ .babelrc exists"
else
    echo -e "  ${YELLOW}⚠ .babelrc missing (using inline config)${NC}"
fi

echo ""

# Step 5: Build using npx (avoids global conflicts)
echo -e "${BLUE}Step 5: Building with webpack (using npx)...${NC}"
echo "This may take 1-2 minutes..."
echo ""

START_TIME=$(date +%s)

npx webpack --mode production --config webpack.config.js 2>&1 | tee /tmp/webpack-build.log

BUILD_EXIT_CODE=${PIPESTATUS[0]}
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "Build time: ${DURATION} seconds"
echo ""

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo -e "  ✓✓✓ Build Succeeded! ✓✓✓"
    echo -e "==========================================${NC}"
    echo ""
else
    echo -e "${RED}=========================================="
    echo -e "  ✗✗✗ Build Failed ✗✗✗"
    echo -e "==========================================${NC}"
    echo ""
    echo "Last 30 lines of build output:"
    tail -30 /tmp/webpack-build.log
    echo ""
    echo "Full log: /tmp/webpack-build.log"
    exit 1
fi

# Step 6: Verify output
echo -e "${BLUE}Step 6: Verifying build output...${NC}"

if [ ! -d "dist" ]; then
    echo -e "${RED}✗ dist directory not found${NC}"
    exit 1
fi

echo "Build output:"
ls -lh dist/ | sed 's/^/  /'
echo ""

BUNDLE_FILE=$(ls dist/bundle*.js 2>/dev/null | head -1)
INDEX_FILE="dist/index.html"

if [ -f "$BUNDLE_FILE" ]; then
    BUNDLE_SIZE=$(du -h "$BUNDLE_FILE" | awk '{print $1}')
    echo -e "  ${GREEN}✓${NC} bundle.js (${BUNDLE_SIZE})"
else
    echo -e "  ${RED}✗${NC} bundle.js - NOT FOUND"
    exit 1
fi

if [ -f "$INDEX_FILE" ]; then
    INDEX_SIZE=$(du -h "$INDEX_FILE" | awk '{print $1}')
    echo -e "  ${GREEN}✓${NC} index.html (${INDEX_SIZE})"
else
    echo -e "  ${RED}✗${NC} index.html - NOT FOUND"
    exit 1
fi

echo ""

# Step 7: Summary
echo -e "${GREEN}=========================================="
echo -e "  ✓✓✓ All Tests Passed! ✓✓✓"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  • Dependencies: ✓ Installed"
echo "  • Build: ✓ Succeeded (${DURATION}s)"
echo "  • Output: ✓ Verified"
echo "  • Bundle size: ${BUNDLE_SIZE}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. The build configuration is CORRECT"
echo "  2. Docker build should also succeed"
echo "  3. Run: cd /root/dimensio/deploy && ./deploy-docker-only.sh"
echo ""
echo -e "${BLUE}Logs saved to:${NC}"
echo "  • npm install: /tmp/npm-install.log"
echo "  • webpack build: /tmp/webpack-build.log"
echo ""
