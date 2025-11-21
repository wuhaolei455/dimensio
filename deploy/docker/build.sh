#!/bin/bash

# Dimensio Docker Build Script
# This script pre-pulls base images and then builds the Docker containers

set -e  # Exit on error

echo "======================================"
echo "Dimensio Docker Build Script"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Pre-pull base images
echo -e "${BLUE}[1/4] Pre-pulling base images...${NC}"
echo "This ensures faster builds by using the configured Docker mirrors"
echo ""

echo -e "${YELLOW}Pulling python:3.9-slim...${NC}"
docker pull python:3.9-slim

echo -e "${YELLOW}Pulling node:18-alpine...${NC}"
docker pull node:18-alpine

echo -e "${YELLOW}Pulling nginx:alpine...${NC}"
docker pull nginx:alpine

echo -e "${GREEN}✓ Base images pulled successfully${NC}"
echo ""

# Step 2: Build Docker containers
echo -e "${BLUE}[2/4] Building Docker containers...${NC}"
cd "$(dirname "$0")"

if [ "$1" = "--no-cache" ]; then
    echo "Building with --no-cache option"
    docker compose build --no-cache
else
    echo "Building with cache (use --no-cache to rebuild from scratch)"
    docker compose build
fi

echo -e "${GREEN}✓ Build completed successfully${NC}"
echo ""

# Step 3: Show images
echo -e "${BLUE}[3/4] Docker images created:${NC}"
docker compose images

echo ""

# Step 4: Instructions
echo -e "${BLUE}[4/4] Next steps:${NC}"
echo "To start the services, run:"
echo "  cd deploy/docker && docker compose up -d"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop services:"
echo "  docker compose down"
echo ""
echo -e "${GREEN}======================================"
echo "Build completed successfully!"
echo "======================================${NC}"
